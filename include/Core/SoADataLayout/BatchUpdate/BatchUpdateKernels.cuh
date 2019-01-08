#include "../Conf/EdgeOperations.cuh"

template <typename HornetDeviceT, typename vid_t, typename degree_t>
__global__
void get_vertex_degrees_kernel(
        HornetDeviceT& hornet,
        const vid_t * __restrict__ vertex_id,
        const size_t vertex_id_count,
        degree_t *    __restrict__ vertex_degrees) {
    size_t     id = blockIdx.x * blockDim.x + threadIdx.x;
    size_t stride = gridDim.x * blockDim.x;

    for (auto i = id; i < vertex_id_count; i += stride)
        vertex_degrees[i] = hornet.vertex(vertex_id[i]).degree();
}

template <typename HornetDeviceT, typename vid_t, typename degree_t>
void get_vertex_degrees(HornetDeviceT& hornet,
        thrust::device_vector<vid_t>& vertex_ids,
        thrust::device_vector<degree_t>& vertex_degrees) {
    const unsigned BLOCK_SIZE = 128;
    get_vertex_degrees_kernel
        <<< xlib::ceil_div<BLOCK_SIZE>(vertex_ids.size()), BLOCK_SIZE >>>
        (hornet, vertex_ids.data().get(), vertex_ids.size(), vertex_degrees.data().get());
}

template <int BLOCK_SIZE, typename HornetDeviceT, typename vid_t, typename degree_t, typename SoAPtrT>
__global__
void mark_duplicate_edges_kernel(
        HornetDeviceT hornet,//
        const size_t graph_offsets_count,//
        const degree_t * __restrict__ graph_offsets,//
        const degree_t * __restrict__ batch_offsets,//
        const vid_t    * __restrict__ unique_src_ids,//
        SoAPtrT                          batch_edges,
        const degree_t * __restrict__ duplicate_flag) {
    const vid_t * batch_dst_ids = batch_edges.template get<0>();
    const auto& lambda = [&] (int pos, degree_t offset) {
                    auto     vertex = hornet.vertex(unique_src_ids[pos]);
                    assert(offset < vertex.degree());
                    auto e = vertex.edge(offset);
                    auto        dst = e.dst_id();
                    int start = batch_offsets[pos];
                    int end   = batch_offsets[pos + 1];
                    int found = xlib::lower_bound_left(
                            batch_dst_ids + start,
                            end - start,
                            dst);
                    if ((found >= 0) && (dst == batch_dst_ids[start + found])) {
                        duplicate_flag[start + found] = 0;
                    }
                };
    xlib::binarySearchLB<BLOCK_SIZE>(graph_offsets, graph_offsets_count, nullptr, lambda);
}

//Sets false to all locations in duplicate_flag if the corresponding batch_dst_ids
//is present in the graph
template <typename HornetDeviceT, typename vid_t, typename degree_t, typename SoAPtrT>
void mark_duplicate_edges(
        HornetDeviceT& hornet,
        thrust::device_vector<vid_t>& vertex_ids,
        //const vid_t * batch_dst_ids,
        SoAPtrT batch_edges,
        thrust::device_vector<degree_t>& batch_offsets,
        thrust::device_vector<degree_t>& graph_offsets,
        thrust::device_vector<degree_t>& duplicate_flag,
        const degree_t total_work) {
    const unsigned BLOCK_SIZE = 128;
    int smem = xlib::DeviceProperty::smem_per_block<degree_t>(BLOCK_SIZE);
    int num_blocks = xlib::ceil_div(total_work, smem);
    mark_duplicate_edges_kernel<BLOCK_SIZE>
        <<< num_blocks, BLOCK_SIZE >>>(
                hornet,
                graph_offsets.size(),
                graph_offsets.data().get(),
                batch_offsets.data().get(),
                vertex_ids.data().get(),
                batch_edges.template get_tail(),
                duplicate_flag.data().get());
}

template <typename CSoAPtrT, typename degree_t>
void write_unique_edges_kernel(
        CSoAPtrT in,
        CSoAPtrT out,
        const degree_t * __restrict__ offsets,
        const size_t num_elements) {
    size_t     id = blockIdx.x * blockDim.x + threadIdx.x;
    size_t stride = gridDim.x * blockDim.x;
    for (auto i = id; i < num_elements; i += stride) {
        if (offsets[i] != offsets[i+1]) {
            out[offsets[i]] = in[i];
        }
    }
}

template <typename CSoADataT, typename degree_t>
void write_unique_edges(
        CSoADataT& in,
        CSoADataT& out,
        thrust::device_vector<degree_t>& offsets) {
    auto in_ptr = in.get_soa_ptr();
    auto out_ptr = out.get_soa_ptr();
    const unsigned BLOCK_SIZE = 128;
    const size_t num_elements = offsets.size() - 1;
    write_unique_edges_kernel
        <<< xlib::ceil_div<BLOCK_SIZE>(num_elements), BLOCK_SIZE >>>
        (in_ptr, out_ptr, offsets.data().get(), num_elements);
}

template <typename HornetDeviceT, typename vid_t, typename degree_t, typename SoAPtrT>
__global__
void buildReallocateVerticesQueue(
        HornetDeviceT hornet,
        const vid_t * __restrict__ unique_sources,
        const degree_t * __restrict__ unique_degrees,
        const degree_t unique_sources_count,
        vid_t * __restrict__ realloc_sources,
        SoAPtrT realloc_vertex_access,
        SoAPtrT new_vertex_access,
        degree_t * __restrict__ realloc_sources_count,
        const bool is_insert,
        degree_t * __restrict__ graph_degrees) {
    int     id = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = gridDim.x * blockDim.x;
    xlib::DeviceQueueOffset queue(realloc_sources_count);

    for (auto i = id; i < unique_sources_count; i += stride) {
        vid_t        src          = unique_sources[i];
        degree_t requested_degree = unique_degrees[i];
        auto vertex = hornet.vertex(src);

        degree_t old_degree = vertex.degree();

        if (graph_degrees != nullptr) { graph_degrees[i] = old_degree; }

        degree_t new_degree = is_insert ?
            old_degree + requested_degree :
            old_degree - requested_degree;

        bool realloc_flag = is_insert ?
            new_degree > vertex.limit() :
            new_degree <= (vertex.limit() / 2);

        if (realloc_flag) {
            int offset = queue.offset();
            realloc_sources[offset] = src;
            auto realloc_vertex_access_ref = realloc_vertex_access[offset];
            realloc_vertex_access_ref.template get<0>() = old_degree;
            realloc_vertex_access_ref.template get<1>() = vertex.edge_block_ptr();
            realloc_vertex_access_ref.template get<2>() = vertex.vertex_offset();
            realloc_vertex_access_ref.template get<3>() = vertex.edges_per_block();
            auto new_vertex_access_ref = new_vertex_access[offset];
            new_vertex_access_ref.template get<0>() = new_degree;
        } else {
            vertex.set_degree(new_degree);
        }
    }
}

template <int BLOCK_SIZE, typename HornetDeviceT, typename degree_t, typename SoAPtrT>
__global__
void move_adjacency_lists_kernel(
        HornetDeviceT hornet,
        SoAPtrT d_realloc_v_data,
        SoAPtrT d_new_v_data,
        const degree_t* __restrict__ graph_offsets,
        const size_t graph_offsets_count) {
    using EdgePtrT = HornetDeviceT::VertexT::EdgeT::EdgeContainerT;
    const auto& lambda = [&] (int pos, degree_t offset) {
        auto realloc_ref = d_realloc_v_data[pos];
        auto new_ref = d_new_v_data[pos];
        EdgePtrT r_eptr(realloc_ref. template get<1>(), realloc_ref. template get<3>());
        EdgePtrT n_eptr(new_ref. template get<1>(), new_ref. template get<3>());
        n_ptr[new_ref. template get<2>() + offset] = r_eptr[realloc_ref. template get<2>() + offset];
    };
    xlib::binarySearchLB<BLOCK_SIZE>(graph_offsets, graph_offsets_count, nullptr, lambda);
}

template <typename vid_, typename degree_t, typename SoAPtrT>
__global__
void set_vertex_meta_data(
        vid_t * const realloc_src,
        SoAPtr<degree_t, xlib::byte_t*, degree_t, degree_t, VertexMetaTypes...> vertex_access_ptr,
        SoAPtr<degree_t, xlib::byte_t*, degree_t, degree_t> d_new_v_data,
        const degree_t reallocated_vertices_count) noexcept {
    size_t     id = blockIdx.x * blockDim.x + threadIdx.x;
    size_t stride = gridDim.x * blockDim.x;

    for (auto i = id; i < reallocated_vertices_count; i += stride) {
        auto old_ref = vertex_access_ptr[realloc_src[i]];
        auto new_ref = d_new_v_data[i];
        new_ref.template get<0>() = old_ref.template get<0>();
        new_ref.template get<1>() = old_ref.template get<1>();
        new_ref.template get<2>() = old_ref.template get<2>();
        new_ref.template get<3>() = old_ref.template get<3>();
    }
}

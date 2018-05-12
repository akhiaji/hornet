/**
 * @author Federico Busato                                                  <br>
 *         Univerity of Verona, Dept. of Computer Science                   <br>
 *         federico.busato@univr.it
 * @date September, 2017
 * @version v2
 *
 * @copyright Copyright © 2017 Hornet. All rights reserved.
 *
 * @license{<blockquote>
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * * Redistributions of source code must retain the above copyright notice, this
 *   list of conditions and the following disclaimer.
 * * Redistributions in binary form must reproduce the above copyright notice,
 *   this list of conditions and the following disclaimer in the documentation
 *   and/or other materials provided with the distribution.
 * * Neither the name of the copyright holder nor the names of its
 *   contributors may be used to endorse or promote products derived from
 *   this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 * </blockquote>}
 */
namespace hornet {
namespace gpu {


template<unsigned N, unsigned SIZE>
struct AssignMetaData {
    template <typename... EdgeMetaTypes, typename vid_t, typename degree_t>
    static void assign(
            CSoAPtr<vid_t, EdgeMetaTypes...> e_ptr, degree_t vertex_block_offset,
            SoAPtr<EdgeMetaTypes const...> edge_meta, degree_t vertex_csr_offset,
            const degree_t vertex_degree) {
        if (edge_meta.template get<N>() != nullptr) {
            for (degree_t i = 0; i < vertex_degree; ++i) {
                e_ptr[vertex_block_offset + i].template get<N+1>() = edge_meta[vertex_csr_offset + i].template get<N>();
            }
        }
        AssignMetaData<N+1, SIZE>::assign(e_ptr, vertex_block_offset, edge_meta, vertex_csr_offset, vertex_degree);
    }
};

template<unsigned N>
struct AssignMetaData<N, N> {
    template <typename... EdgeMetaTypes, typename vid_t, typename degree_t>
    static void assign(
            CSoAPtr<vid_t, EdgeMetaTypes...> e_ptr, degree_t vertex_block_offset,
            SoAPtr<EdgeMetaTypes const...> edge_meta, degree_t vertex_csr_offset,
            const degree_t vertex_degree) {
        if (edge_meta.template get<N>() != nullptr) {
            for (degree_t i = 0; i < vertex_degree; ++i) {
                e_ptr[vertex_block_offset + i].template get<N+1>() = edge_meta[vertex_csr_offset + i].template get<N>();
            }
        }
    }
};


#define HORNET Hornet<TypeList<VertexMetaTypes...>,\
                      TypeList<EdgeMetaTypes...>,\
                      vid_t,\
                      degree_t>

template <typename... VertexMetaTypes, typename... EdgeMetaTypes,
    typename vid_t, typename degree_t>
int HORNET::_instance_count = 0;

template <typename... VertexMetaTypes, typename... EdgeMetaTypes,
    typename vid_t, typename degree_t>
HORNET::
Hornet(HornetInit<
    TypeList<VertexMetaTypes...>,
    TypeList<EdgeMetaTypes...>,
    vid_t, degree_t>& h_init) noexcept :
    _nV(h_init.nV()),
    _nE(h_init.nE()),
    _id(_instance_count++),
    _edge_access_data(h_init.nV()),
    _vertex_meta_data(h_init.nV()) {
    initialize(h_init);
}

template <typename... VertexMetaTypes, typename... EdgeMetaTypes,
    typename vid_t, typename degree_t>
void
HORNET::
initialize(HornetInit<
    TypeList<VertexMetaTypes...>,
    TypeList<EdgeMetaTypes...>,
    vid_t, degree_t>& h_init) noexcept {

    SoAData<EdgeAccessT, DeviceType::HOST> e_access(_nV);
    auto e_d = e_access.get_soa_ptr();

    std::unordered_map<
        xlib::byte_t*,
        BlockArray<TypeList<vid_t, EdgeMetaTypes...>, DeviceType::HOST>> h_blocks;

    const auto * offsets = h_init.csr_offsets();
    const auto * edges   = h_init.csr_edges();
    for (int i = 0; i < h_init.nV(); ++i) {
        auto degree = offsets[i + 1] - offsets[i];
        auto device_ad = _ba_manager.insert(degree);
        auto e_ref = e_d[i];
        e_ref.template get<0>() = degree;
        e_ref.template get<1>() = device_ad.edge_block_ptr;
        e_ref.template get<2>() = device_ad.vertex_offset;
        e_ref.template get<3>() = device_ad.edges_per_block;

        CSoAPtr<vid_t, EdgeMetaTypes...> e_ptr;

        auto search = h_blocks.find(device_ad.edge_block_ptr);
        if (search != h_blocks.end()) {
            e_ptr = CSoAPtr<vid_t, EdgeMetaTypes...>(search->second.get_blockarray_ptr(), device_ad.edges_per_block);
        } else {
            BlockArray<TypeList<vid_t, EdgeMetaTypes...>, DeviceType::HOST> new_block_array(
                    xlib::ceil_log2(degree),
                    device_ad.edges_per_block);
            e_ptr = CSoAPtr<vid_t, EdgeMetaTypes...>(new_block_array.get_blockarray_ptr(), device_ad.edges_per_block);
            h_blocks.insert(std::make_pair(device_ad.edge_block_ptr, std::move(new_block_array)));
        }
        for (degree_t j = 0; j < degree; ++j) {
            e_ptr[device_ad.vertex_offset + j].template get<0>() = edges[offsets[i] + j];
        }
        AssignMetaData<0, sizeof...(EdgeMetaTypes) - 1>::assign(
                e_ptr, device_ad.vertex_offset,
                h_init.edge_meta_data_ptr(), offsets[i], degree);
    }

    _edge_access_data.template copy(e_access);
    for(auto &b : h_blocks) {
        DeviceCopy::copy(b.second.get_blockarray_ptr(),
                DeviceType::HOST,
                b.first,
                DeviceType::DEVICE,
                xlib::SizeSum<vid_t, EdgeMetaTypes...>::value * b.second.capacity());
    }

}

}
}

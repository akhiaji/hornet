namespace hornet {
namespace gpu {

template <typename... VertexMetaTypes, typename... EdgeMetaTypes,
    typename vid_t, typename degree_t>
HORNET::HornetDeviceT
HORNET::
device(void) {
    return HornetDeviceT(_nV, _nE, _vertex_data.get_soa_ptr());
}

template <typename... VertexMetaTypes, typename... EdgeMetaTypes,
    typename vid_t, typename degree_t>
void
HORNET::
insert(BatchUpdate<TypeList<vid_t, vid_t, EdgeMetaTypes...>, degree_t>& batch, bool removeBatchDuplicates, bool removeGraphDuplicates) {
    //Preprocess batch according to user preference
    batch.preprocess(device(), removeBatchDuplicates, removeGraphDuplicates);

    reallocate_vertices(batch, true);

    appendBatchEdges(batch);
}

template <typename... VertexMetaTypes, typename... EdgeMetaTypes,
    typename vid_t, typename degree_t>
void
HORNET::
reallocate_vertices(BatchUpdate<TypeList<vid_t, vid_t, EdgeMetaTypes...>, degree_t>& batch,
        const bool is_insert) {
    vid_t * r_vertex_id;
    SoAPtr<degree_t, xlib::byte_t*, degree_t, degree_t> h_realloc_v_data;
    SoAPtr<degree_t, xlib::byte_t*, degree_t, degree_t> h_new_v_data;
    SoAPtr<degree_t, xlib::byte_t*, degree_t, degree_t> d_realloc_v_data;
    SoAPtr<degree_t, xlib::byte_t*, degree_t, degree_t> d_new_v_data;
    degree_t reallocated_vertices_count;

    //Get list of vertices that need to be reallocated
    //realloc_vertex_meta_data contains old adjacency list information.
    //new_vertex_meta_data contains buffer to store new adjacency list information from block array manager calls below

    batch.get_reallocate_vertices_meta_data(
            device(), r_vertex_id, h_realloc_v_data, h_new_v_data, d_realloc_v_data, d_new_v_data, reallocated_vertices_count, is_insert);

    for (degree_t i = 0; i < reallocated_vertices_count; i++) {
        auto ref = h_new_v_data[i];
        auto access_data = _ba_manager.insert(ref.template get<0>());
        ref.template get<1>() = access_data.edge_block_ptr;;
        ref.template get<2>() = access_data.vertex_offset;
        ref.template get<3>() = access_data.edges_per_block;
    }

    //Move adjacency list and edit vertex access data
    batch.move_adjacency_lists(device(), r_vertex_id, _vertex_data.get_soa_ptr(), h_realloc_v_data, h_new_v_data, d_realloc_v_data, d_new_v_data, reallocated_vertices_count);

    for (degree_t i = 0; i < reallocated_vertices_count; i++) {
        auto ref = h_realloc_v_data[i];
        _ba_manager.remove(ref.template get<0>(), ref.template get<1>(), ref.template get<2>());
    }

}

template <typename... VertexMetaTypes, typename... EdgeMetaTypes,
    typename vid_t, typename degree_t>
void
HORNET::
appendBatchEdges(BatchUpdate<TypeList<vid_t, vid_t, EdgeMetaTypes...>, degree_t>& batch) {
    vid_t * batch_sources;
    degree_t * batch_offsets;
    degree_t * batch_old_degrees;
    CSoAPtr<TypeList<vid_t, EdgeMetaTypes...>> edge_ptr;
    batch.get_batch_meta_data(batch_sources, batch_offsets, batch_old_degrees, edge_ptr);

    //TODO : bulkCopyAdjLists
}

}
}

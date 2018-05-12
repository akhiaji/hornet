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
#include "Host/Metaprogramming.hpp"

namespace hornet {

#define BATCH_UPDATE BatchUpdate<TypeList<EdgeMetaTypes...>,\
                               vid_t,\
                               degree_t>

template <typename... EdgeMetaTypes,
    typename vid_t, typename degree_t>
inline
BATCH_UPDATE::
BatchUpdate(
        const degree_t num_edges,
        const vid_t* src,
        const vid_t* dst,
        BatchUpdateType batch_update_type = BatchUpdateType::HOST) noexcept :
        _nE(num_edges),
        _src(src),
        _batch_update_type(batch_update_type) {
    _edge_data.template set<0>(dst);
}

template <typename... EdgeMetaTypes,
    typename vid_t, typename degree_t>
inline BatchUpdateType
BATCH_UPDATE::type(void) const noexcept {
    return _batch_update_type;
}

template <typename... EdgeMetaTypes,
    typename vid_t, typename degree_t>
inline void
BATCH_UPDATE::
insertEdgeData(EdgeMetaTypes const * const... edge_meta_data) noexcept {
    vid_t * dst = _edge_data.template get<0>();
    SoAPtr<vid_t const, EdgeMetaTypes const...> e_d(dst, edge_meta_data...);
    _edge_data = e_d;
}

template <typename... EdgeMetaTypes,
    typename vid_t, typename degree_t>
template <unsigned N>
inline void
BATCH_UPDATE::
insertEdgeData(typename xlib::SelectType<N, EdgeMetaTypes const * const...>::type edge_meta_data) noexcept {
    _edge_meta.template set<N+1>(edge_meta_data);
}

template <typename... EdgeMetaTypes,
    typename vid_t, typename degree_t>
inline degree_t
BATCH_UPDATE::
nE(void) const noexcept {
    return _nE;
}

template <typename... EdgeMetaTypes,
    typename vid_t, typename degree_t>
inline const vid_t*
batch_update::
src(void) const noexcept {
    return _src;
}

template <typename... EdgeMetaTypes,
    typename vid_t, typename degree_t>
inline const vid_t*
batch_update::
dst(void) const noexcept {
    return _edge_data.template get<0>();
}

//template <typename... EdgeMetaTypes,
//    typename vid_t, typename degree_t>
//inline SoAPtr<EdgeMetaTypes const...>
//BATCH_UPDATE::
//edge_meta_data_ptr(void) const noexcept {
//    return _edge_meta_data;
//}

}

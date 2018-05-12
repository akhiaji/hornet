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

#define HORNET_DEVICE HornetDevice<TypeList<VertexMetaTypes...>,\
                                   TypeList<EdgeMetaTypes...>,\
                                   vid_t,\
                                   degree_t>

template <typename... VertexMetaTypes, typename... EdgeMetaTypes,
    typename vid_t, typename degree_t>
HORNET_DEVICE::
HornetDevice(
    vid_t nV,
    degree_t nE,
    SoAPtr<VertexMetaTypes...> vertex_meta_data,
    SoAPtr<degree_t, xlib::byte_t*, degree_t, degree_t> edge_access_data) noexcept :
    _nV(nV), _nE(nE), _vertex_meta_data(vertex_meta_data), _edge_access_data(edge_access_data) {}

template <typename... VertexMetaTypes, typename... EdgeMetaTypes,
    typename vid_t, typename degree_t>
HOST_DEVICE
vid_t
HORNET_DEVICE::
nV() const noexcept {
    return _nV;
}

template <typename... VertexMetaTypes, typename... EdgeMetaTypes,
    typename vid_t, typename degree_t>
HOST_DEVICE
degree_t
HORNET_DEVICE::
nE() const noexcept {
    return _nE;
}

template <typename... VertexMetaTypes, typename... EdgeMetaTypes,
    typename vid_t, typename degree_t>
HOST_DEVICE
HORNET_DEVICE::VertexT
HORNET_DEVICE::
vertex(const vid_t index) const noexcept {
    return VertexT(*this, index);
}

template <typename... VertexMetaTypes, typename... EdgeMetaTypes,
    typename vid_t, typename degree_t>
HOST_DEVICE
SoAPtr<degree_t, xlib::byte_t*, degree_t, degree_t>&
HORNET_DEVICE::
get_edge_ptr(void) const noexcept {
    return _edge_access_data;
}

template <typename... VertexMetaTypes, typename... EdgeMetaTypes,
    typename vid_t, typename degree_t>
HOST_DEVICE
typename std::enable_if<
    (0 != sizeof...(VertexMetaTypes)),
    SoAPtr<VertexMetaTypes...>&>::type
HORNET_DEVICE::
get_vertex_meta_ptr(void) const noexcept {
    return _vertex_meta_data;
}

#undef HORNETDEVICE
} // namespace hornets_nest

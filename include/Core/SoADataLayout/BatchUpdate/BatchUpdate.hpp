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
#pragma once
#include "../Conf/HornetConf.hpp"

namespace hornet {

//enum class BatchUpdateType { HOST, DEVICE };

using BatchUpdateType = DeviceType;

template <typename,
         typename = VID_T, typename = DEGREE_T>
         class BatchUpdate;

template <typename... EdgeMetaTypes,
    typename vid_t, typename degree_t>
class BatchUpdate<
    TypeList<EdgeMetaTypes...>,
    vid_t, degree_t> {
    degree_t                       _nE        { 0 };
    const vid_t *                  _src { nullptr };
    //const vid_t *                  _dst { nullptr };
    BatchUpdateType _batch_update_type  {BatchUpdateType::HOST};

    SoAPtr<vid_t const, EdgeMetaTypes const...>  _edge_data;

public:
    BatchUpdate(
            const degree_t num_edges,
            const vid_t* src,
            const vid_t* dst,
            BatchUpdateType update_type = BatchUpdateType::HOST) noexcept;

    BatchUpdateType type() const noexcept;

    void insertEdgeData(EdgeMetaTypes const * const... edge_meta_data) noexcept;

    template <unsigned N>
    void insertEdgeData(typename xlib::SelectType<N, EdgeMetaTypes const * const...>::type edge_meta_data) noexcept;

    degree_t nE(void) const noexcept;

    const vid_t* src(void) const noexcept;

    const vid_t* dst(void) const noexcept;

    //SoAPtr<EdgeMetaTypes const...>   edge_meta_data_ptr(void) const noexcept;
};

}

#include "BatchUpdate.i.hpp"

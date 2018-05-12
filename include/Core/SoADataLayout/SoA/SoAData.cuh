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
#include "../Conf/Common.hpp"
#include "SoAPtr.cuh"
#include <Device/Util/SafeCudaAPI.cuh>  //cuMalloc
#include <Device/Util/SafeCudaAPISync.cuh>

namespace hornet {

template <typename, DeviceType = DeviceType::DEVICE> class SoAData;
template <typename, DeviceType = DeviceType::DEVICE> class CSoAData;

template<typename... Ts, DeviceType device_t>
class SoAData<TypeList<Ts...>, device_t> {
    template<typename, DeviceType> friend class SoAData;
    int           _num_items;
    SoAPtr<Ts...> _soa;

    public:
    SoAData(const int num_items) noexcept;

    ~SoAData(void) noexcept;

    SoAData& operator=(const SoAData&) = delete;
    SoAData& operator=(SoAData&&) = delete;

    template<DeviceType d_t>
    SoAData(const SoAData<TypeList<Ts...>, d_t>& other) noexcept;

    template<DeviceType d_t>
    SoAData(SoAData<TypeList<Ts...>, d_t>&& other) noexcept;

    SoAPtr<Ts...>& get_soa_ptr(void) noexcept;
    const SoAPtr<Ts...>& get_soa_ptr(void) const noexcept;

    template<DeviceType d_t>
    void copy(const SoAData<TypeList<Ts...>, d_t>& other) noexcept;

    int get_num_items(void) noexcept;
};

template<typename... Ts, DeviceType device_t>
class CSoAData<TypeList<Ts...>, device_t> {
    template<typename, DeviceType> friend class CSoAData;
    int            _num_items;
    CSoAPtr<Ts...> _soa;

    public:
    CSoAData(const int num_items) noexcept;

    ~CSoAData(void) noexcept;

    CSoAData& operator=(const CSoAData&);

    CSoAData& operator=(CSoAData&&);

    CSoAData(const CSoAData<TypeList<Ts...>, device_t>& other) noexcept;

    CSoAData(CSoAData<TypeList<Ts...>, device_t>&& other) noexcept;

    template<DeviceType d_t>
    CSoAData(const CSoAData<TypeList<Ts...>, d_t>& other) noexcept;

    template<DeviceType d_t>
    CSoAData(CSoAData<TypeList<Ts...>, d_t>&& other) noexcept;

    CSoAPtr<Ts...>& get_soa_ptr(void) noexcept;
    const CSoAPtr<Ts...>& get_soa_ptr(void) const noexcept;

    void copy(const SoAPtr<TypeList<const Ts...>>& other, const DeviceType other_d_t, const int other_num_items) noexcept;

    template<DeviceType d_t>
    void copy(const CSoAData<TypeList<const Ts...>, d_t>& other) noexcept;

    int get_num_items(void) noexcept;
};

}

#include "impl/SoAData.i.cuh"

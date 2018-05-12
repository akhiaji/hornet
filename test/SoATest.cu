#include <iostream>
#include "Core/SoADataLayout/HornetDevice/HornetDevice.cuh"
#include "Core/SoADataLayout/MemoryManager/BlockArray/BlockArray.hpp"
#include "Core/SoADataLayout/Hornet.cuh"
#include "Core/SoADataLayout/HornetInitialize/HornetInit.hpp"

using namespace hornet;

#if 0
int main(int argc, char *argv[]) {
    //BlockArrayManager<TypeList<int, float, int>, DeviceType::DEVICE, DEGREE_T> _bm;
    //std::array<
    //    std::unordered_map<
    //        xlib::byte_t*,
    //        BlockArray<TypeList<int, float, int>, DeviceType::DEVICE>>,
    //32> _ba_map_arr;


    using BAT = BlockArray<TypeList<int, float, int>, DeviceType::DEVICE>;
    BAT _ba(1024, 32);
    std::unordered_map<
        xlib::byte_t*,
        BAT
            > _ba_map;
    xlib::byte_t* block_ptr = reinterpret_cast<xlib::byte_t *>(_ba.get_blockarray_ptr());
    _ba_map.insert(
            std::pair<xlib::byte_t*,
            BAT
            >
            (block_ptr, std::move(_ba)));

    //CSoAData<TypeList<int, float, int>, DeviceType::HOST> f(10);
    //CSoAData<TypeList<int, float, int>, DeviceType::DEVICE> fs(std::move(f));
    //CSoAData<TypeList<int, float, int>, DeviceType::DEVICE> ft(fs);
    return 0;
}
#else
int main(int argc, char *argv[]) {
    //CSoAData<TypeList<int, float, int>, DeviceType::HOST> f(10);
    //SoAPtr<int, int, int, xlib::byte_t*> e_a;
    //SoAPtr<float, int> f_a;
//
//    std::cout<<
//        "\n"<<f.get_soa_ptr().get<0>()<<
//        "\n"<<f.get_soa_ptr().get<1>()<<
//        "\n"<<f.get_soa_ptr().get<2>();
//
//    std::cout<<"\n";
//    auto ff = f.get_soa_ptr();
//
//    std::cout<<"\n";
//    std::cout<<
//        "\n"<<ff.get<0>()<<
//        "\n"<<ff.get<1>()<<
//        "\n"<<ff.get<2>();
//    f_a = ff;
//    std::cout<<"\n";
//    std::cout<<
//        "\n"<<f_a.get<0>()<<
//        "\n"<<f_a.get<1>()<<
//        "\n"<<f_a.get<2>();
//
    using EdgeAccessT = SoAPtr<int, xlib::byte_t*, int, int>;
    using VerteMetaT = TypeList<int>;
    using EdgeMetaT = TypeList<float, float>;
    SoAPtr<int> v_m;
    using HornetDeviceT = hornet::HornetDevice<
        VerteMetaT, EdgeMetaT,
        int, int>;

    EdgeAccessT e_a;
    HornetDeviceT h(10, 20, v_m, e_a);

    const int * dummy_offset = nullptr;
    const int * dummy_edges = nullptr;
    HornetInit<VerteMetaT, EdgeMetaT, int, int> init(10, 20, dummy_offset, dummy_edges);
    //const float * e_1 = reinterpret_cast<const float*>(10);
    //const float * e_2 = reinterpret_cast<const float*>(11);

    hornet::gpu::Hornet<VerteMetaT, EdgeMetaT, int, int> hornet(init);

    //const float * e_1_n = reinterpret_cast<const float*>(20);
    //const float * e_2_n = reinterpret_cast<const float*>(21);

    //const int * v_1 = reinterpret_cast<const int*>(50);
    //const int * v_2 = reinterpret_cast<const int*>(51);

    //init.insertEdgeData(e_1, e_2);
    //std::cout<<init.edge_meta_data_ptr().get<0>()<<"\n";
    //std::cout<<init.edge_meta_data_ptr().get<1>()<<"\n";

    //std::cout<<"\n";
    //init.insertEdgeData<0>(e_1_n);
    //init.insertEdgeData<1>(e_2_n);
    //std::cout<<init.edge_meta_data_ptr().get<0>()<<"\n";
    //std::cout<<init.edge_meta_data_ptr().get<1>()<<"\n";

    //init.insertVertexData(v_1);
    //std::cout<<init.vertex_meta_data_ptr().get<0>()<<"\n";

    //init.insertVertexData<0>(v_2);
    //std::cout<<init.vertex_meta_data_ptr().get<0>()<<"\n";
    ////for (int i = 0; i < 10; ++i) {
    ////    auto r = ff[i];
    ////    std::cout<<"\n"<<r.get<0>();
    ////    std::cout<<"\t"<<r.get<1>();
    ////    std::cout<<"\t"<<r.get<2>();
    ////}
    //CSoAData<TypeList<int, float, int>, DeviceType::HOST> d(10);
    //std::cout<<"Create d\n";
    //std::cout<<
    //    "\n"<<d.get_soa_ptr().get<0>()<<
    //    "\n"<<d.get_soa_ptr().get<1>()<<
    //    "\n"<<d.get_soa_ptr().get<2>();
    //std::cout<<"d = f\n";
    //std::cout<<
    //    "\n"<<d.get_soa_ptr().get<0>()<<
    //    "\n"<<d.get_soa_ptr().get<1>()<<
    //    "\n"<<d.get_soa_ptr().get<2>();
    //auto s = d.get_soa_ptr();
    //for (int i = 0; i < 10; ++i) {
    //    s[i].get<0>() = i;
    //    s[i].get<1>() = i;
    //    s[i].get<2>() = i;
    //}

    //std::cout<<"\n";
    //for (int i = 0; i < 10; ++i) {
    //    auto r = s[i];
    //    std::cout<<"\n"<<r.get<0>();
    //    std::cout<<"\t"<<r.get<1>();
    //    std::cout<<"\t"<<r.get<2>();
    //}

    //s[6] = s[4];
    //s[3] = s[7];

    //std::cout<<"\n";
    //for (int i = 0; i < 10; ++i) {
    //    auto r = s[i];
    //    std::cout<<"\n"<<r.get<0>();
    //    std::cout<<"\t"<<r.get<1>();
    //    std::cout<<"\t"<<r.get<2>();
    //}

    //f.copy(d);
    //std::cout<<"\n";
    //auto sf = f.get_soa_ptr();
    //for (int i = 0; i < 10; ++i) {
    //    auto r = sf[i];
    //    std::cout<<"\n"<<r.get<0>();
    //    std::cout<<"\t"<<r.get<1>();
    //    std::cout<<"\t"<<r.get<2>();
    //}
    //std::cout<<"\n";

    //CSoAData<TypeList<int, float, int>, DeviceType::DEVICE> fs(std::move(f));
    //CSoAData<TypeList<int, float, int>, DeviceType::DEVICE> ft(fs);
    return 0;
}
#endif
/*
int main(int argc, char *argv[]) {
    int * a = new int [10]; for (int i = 0; i < 10; ++i)     {a[i] = i;}
    int * b = new int [10]; for (int i = 0; i < 10; ++i)     {b[i] = 2*i;}
    float * c = new float [10]; for (int i = 0; i < 10; ++i) {c[i] = 3*i;}

    int * na = new int [10]; for (int i = 0; i < 10; ++i)     {na[i] = i;}
    int * nb = new int [10]; for (int i = 0; i < 10; ++i)     {nb[i] = 2*i;}
    float * nc = new float [10]; for (int i = 0; i < 10; ++i) {nc[i] = 3*i;}

    SoAPtr<int, int, float> s(a, b, c);
    SoAPtr<int, int, float> ss;
    ss.set<0>(s.get<0>());
    ss.set<1>(s.get<1>());
    ss.set<2>(s.get<2>());

    SoAPtr<int, int, float> sss;
    SoAPtr<int, int, float> ns(na, nb, nc);

    std::cout<<"Ptrs\n";
    std::cout<<a<<"\n"<<b<<"\n"<<c<<"\n";

    std::cout<<"Ptrs\n";
    std::cout<<s.get<0>()<<"\n"<<s.get<1>()<<"\n"<<s.get<2>()<<"\n";

    std::cout<<"Ptrs\n";
    std::cout<<ss.get<0>()<<"\n"<<ss.get<1>()<<"\n"<<ss.get<2>()<<"\n";

    std::cout<<"Ptrs\n";
    std::cout<<sss.get<0>()<<"\n"<<sss.get<1>()<<"\n"<<sss.get<2>()<<"\n";

    sss = ss;
    std::cout<<"Ptrs\n";
    std::cout<<sss.get<0>()<<"\n"<<sss.get<1>()<<"\n"<<sss.get<2>()<<"\n";

    std::cout<<"Ptrs\n";
    std::cout<<ns.get<0>()<<"\n"<<ns.get<1>()<<"\n"<<ns.get<2>()<<"\n";

    sss = ns;
    std::cout<<"Ptrs\n";
    std::cout<<sss.get<0>()<<"\n"<<sss.get<1>()<<"\n"<<sss.get<2>()<<"\n";

    //auto r = s[5];

    //std::cout<<"===\n";
    //std::cout<<r.get<0>()<<"\n";
    //std::cout<<r.get<1>()<<"\n";
    //std::cout<<r.get<2>()<<"\n";

    //r = s[4];

    //std::cout<<r.get<0>()<<"\n";
    //std::cout<<r.get<1>()<<"\n";
    //std::cout<<r.get<2>()<<"\n";

    delete[] a;
    delete[] b;
    delete[] c;

    delete[] na;
    delete[] nb;
    delete[] nc;
    return 0;
}
*/

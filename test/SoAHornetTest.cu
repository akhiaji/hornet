#include <iostream>
#include <Core/SoADataLayout/Hornet.cuh>

int main(int argc, char *argv[]) {
    cudaSetDevice(1);
    using namespace hornet;  //0  1  2
    std::vector<int> offset = {0, 5, 7, 10};
    std::vector<int> edges = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
    int nV = offset.size() - 1;
    int nE = edges.size();
    HornetInit<EMPTY, TypeList<float>, int, int> init(nV, nE, offset.data(), edges.data());
    gpu::Hornet<EMPTY, TypeList<float>, int, int> g(init);
    g.print();
                            //  
    std::vector<int>   h_src = {0, 0, 1, 1, 2, 0, 2, 2, 2, 1};
    std::vector<int>   h_dst = {2, 2, 0, 3, 1, 1, 4, 2, 3, 0};
    std::vector<float> h_wgt = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
    thrust::device_vector<int> src   = h_src;
    thrust::device_vector<int> dst   = h_dst;
    thrust::device_vector<float> wgt = h_wgt;
    BatchUpdatePtr<TypeList<int, int, float>> ptr(src.size(), src.data().get(), dst.data().get(), wgt.data().get());
    gpu::BatchUpdate<TypeList<int, int, float>, int> batch(ptr);

    g.insert(batch);
    g.print();
//    std::cerr<<"return 0\n";
    return 0;
}

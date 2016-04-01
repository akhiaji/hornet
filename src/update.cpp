
#include <thrust/device_vector.h>
#include <thrust/host_vector.h>


#include <unordered_map>
#include <algorithm>

#include "main.hpp"


using namespace std;

//----------------
//----------------
//----------------
// BatchUpdateData
//----------------
//----------------
//----------------



BatchUpdateData::BatchUpdateData(length_t batchSize_, bool isHost_){
	// numberBytes = sizeof(BatchUpdateData);
	isHost = isHost_;
	numberBytes = batchSize_* (5 * sizeof(vertexId_t)+ 1* sizeof(length_t)) + 3*sizeof (length_t);

	if(isHost){
		mem = (int8_t*)allocHostArray(numberBytes,sizeof(int8_t));
	}
	else{
		mem = (int8_t*)allocDeviceArray(numberBytes,sizeof(int8_t));
	}


	length_t pos=0;
	edgeSrc=(vertexId_t*) (mem + pos); pos+=batchSize_*sizeof(vertexId_t);
	edgeDst=(vertexId_t*) (mem + pos); pos+=batchSize_*sizeof(vertexId_t);
	edgeWeight=(vertexId_t*) (mem + pos); pos+=batchSize_*sizeof(vertexId_t);
	indIncomplete=(vertexId_t*) (mem + pos); pos+=batchSize_*sizeof(vertexId_t);
	indDuplicate=(vertexId_t*) (mem + pos); pos+=batchSize_*sizeof(vertexId_t);
	dupPosBatch=(length_t*) (mem + pos); pos+=batchSize_*sizeof(length_t);
	incCount=(length_t*) (mem + pos); pos+=sizeof(length_t);
	dupCount=(length_t*) (mem + pos); pos+=sizeof(length_t);
		// copyArrayHostToDevice(this,dPtr,1, sizeof(BatchUpdateData));

	batchSize=(length_t*) (mem + pos); pos+=sizeof(length_t);	
	cout << "Pos is  " << pos << endl; 

	if(isHost){
		*incCount=0;
		*dupCount=0;
		*batchSize=batchSize_;
	}
	if(!isHost){
		dPtr=(BatchUpdateData*) allocDeviceArray(1,sizeof(BatchUpdateData));
		copyArrayHostToDevice(this,dPtr,1, sizeof(BatchUpdateData));
	}
}

BatchUpdateData::~BatchUpdateData(){
	if(isHost){
		freeHostArray(mem);
	}
	else{
		freeDeviceArray(dPtr);
		freeDeviceArray(mem);
	}
}


void BatchUpdateData::resetIncCount(){
	if(isHost){
		*incCount=0;
	}
	else{
		checkCudaErrors(cudaMemset(incCount,0,sizeof(length_t)));
	}
}

void BatchUpdateData::resetDuplicateCount(){
	if(isHost){
		*dupCount=0;
	}
	else{
		checkCudaErrors(cudaMemset(dupCount,0,sizeof(length_t)));
	}
}


void BatchUpdateData::copyHostToHost(BatchUpdateData &hBUA){
	if (isHost && hBUA.isHost){
		copyArrayHostToHost(hBUA.mem, mem, numberBytes, sizeof(int8_t));
	}
	else{
		CUSTINGER_ERROR(string("Failure to copy host array to host array in ") + string(typeid(*this).name())+ string(". One of the ARRAY is not a host array"));
	}
}

void BatchUpdateData::copyHostToDevice(BatchUpdateData &hBUA){
	if (!isHost && hBUA.isHost){
		copyArrayHostToDevice(hBUA.mem, mem, numberBytes, sizeof(int8_t));
	}
	else{
		CUSTINGER_ERROR(string("Failure to copy host array to host array in ") + string(typeid(*this).name())+ string(". One of the ARRAY is not a host array"));
	}
}
void BatchUpdateData::copyDeviceToHost(BatchUpdateData &dBUA){
	if (isHost && !dBUA.isHost){	
		copyArrayDeviceToHost(dBUA.mem, mem, numberBytes, sizeof(int8_t));
	}
	else{
		CUSTINGER_ERROR(string("Failure to copy host array to host array in ") + string(typeid(*this).name())+ string(". One of the ARRAY is not a host array"));
	}
}

void BatchUpdateData::copyDeviceToHostDupCount(BatchUpdateData &dBUD){
	if (isHost && !dBUD.isHost){
		copyArrayDeviceToHost(dBUD.dupCount,dupCount,1,sizeof(length_t));
	}
	else{
		CUSTINGER_ERROR(string("Failure to copy device array to host array in ") + string(typeid(*this).name())+ string(". One array is not the right type"));
	}
}

void BatchUpdateData::copyDeviceToHostIncCount(BatchUpdateData &dBUD)
{
	if (isHost && !dBUD.isHost){
		copyArrayDeviceToHost(dBUD.incCount,incCount,1,sizeof(length_t));
	}
	else{
		CUSTINGER_ERROR(string("Failure to copy device array to host array in ") + string(typeid(*this).name())+ string(". One array is not the right type"));
	}
}


//------------
//------------
//------------
// BatchUpdate
//------------
//------------
//------------



BatchUpdate::BatchUpdate(BatchUpdateData &h_bua){

	cout << "Made it this far" << endl << flush;
	if(!h_bua.getisHost()){
		CUSTINGER_ERROR(string(typeid(*this).name()) + string(" expects to receive an update list that is host size"));
	}

	length_t batchSize = *(h_bua.getBatchSize());
	cout << "The batch size is :" << batchSize << endl;


	hData = new BatchUpdateData(batchSize,true);
	cout << "The batch size is :" << batchSize << endl;
	dData = new BatchUpdateData(batchSize,false);
	cout << "Made it this far" << endl << flush;

	hData->copyHostToHost(h_bua);
	dData->copyHostToDevice(h_bua);

	dPtr=(BatchUpdate*) allocDeviceArray(1,sizeof(BatchUpdate));
	copyArrayHostToDevice(this,dPtr,1, sizeof(BatchUpdate));
}


BatchUpdate::~BatchUpdate(){


	freeDeviceArray(dPtr);

	delete hData;
	delete dData;
}


void BatchUpdate::reAllocateMemoryAfterSweep1(cuStinger &custing)
{
	int32_t sum=0; 
	vertexId_t *tempsrc=getHostBUD()->getSrc(),*tempdst=getHostBUD()->getDst(),*incomplete = getHostBUD()->getIndIncomplete();
	length_t incCount = *(getHostBUD()->getIncCount());

	unordered_map <vertexId_t, length_t> h_hmap;

	vertexId_t* h_requireUpdates=(vertexId_t*)allocHostArray(*(getHostBUD()->getBatchSize()), sizeof(vertexId_t));
	length_t* h_overLimit=(length_t*)allocHostArray(*(getHostBUD()->getBatchSize()), sizeof(length_t));

	for (length_t i=0; i<incCount; i++){
		vertexId_t temp = tempsrc[incomplete[i]];
		h_hmap[temp]++;
	}

	length_t countUnique=0;
	for (length_t i=0; i<incCount; i++){
		vertexId_t temp = tempsrc[incomplete[i]];
		if(h_hmap[temp]!=0){
			h_requireUpdates[countUnique]=temp;
			h_overLimit[countUnique]=h_hmap[temp];
			countUnique++;
			h_hmap[temp]=0;
		}
	}

	custing.copyDeviceToHost();

	if(countUnique>0){
		vertexId_t ** h_tempAdjacency = (vertexId_t**) allocHostArray(custing.nv,sizeof(vertexId_t*));
		vertexId_t ** d_tempAdjacency = (vertexId_t**) allocDeviceArray(custing.nv,sizeof(vertexId_t*));
		vertexId_t * d_requireUpdates = (vertexId_t*) allocDeviceArray(countUnique, sizeof(vertexId_t));

		for (length_t i=0; i<countUnique; i++){
			vertexId_t tempVertex = h_requireUpdates[i];
			length_t newMax = custing.updateVertexAllocator(custing.h_max[tempVertex] ,h_overLimit[i]);
			h_tempAdjacency[tempVertex] = (vertexId_t*)allocDeviceArray(newMax, sizeof(vertexId_t));
			custing.h_max[tempVertex] = newMax;
		}

		sort(h_requireUpdates, h_requireUpdates + countUnique);
		copyArrayHostToDevice(h_requireUpdates,d_requireUpdates,countUnique,sizeof(vertexId_t));
		copyArrayHostToDevice(h_tempAdjacency,d_tempAdjacency, custing.nv, sizeof(vertexId_t*));

		custing.copyMultipleAdjacencies(d_tempAdjacency,d_requireUpdates,countUnique);

		for (length_t i=0; i<countUnique; i++){
			vertexId_t tempVertex = h_requireUpdates[i];
			freeDeviceArray(custing.h_adj[tempVertex]);
			custing.h_adj[tempVertex] = h_tempAdjacency[tempVertex];
		}

		custing.copyHostToDevice();

		freeDeviceArray(d_requireUpdates);
		freeHostArray(h_tempAdjacency);
		freeDeviceArray(d_tempAdjacency);
	}

	freeHostArray(h_requireUpdates);
	freeHostArray(h_overLimit);
}

	
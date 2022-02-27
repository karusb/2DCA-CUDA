#ifndef CA_CUDA_HELPERS_HPP
#define CA_CUDA_HELPERS_HPP
#include <string>
#include <iostream>
#include <functional>
#include "cuda_runtime.h"

enum class CACudaAction
{
	Allocation,
	Free,
	HostCopy,
	DeviceCopy,
	Memset,
	Reset,
	SetDevice,
	GetProperty,
	GraphicsResourceMap,
	GraphicsResourceUnmap
};

static std::string CudaActionToString(CACudaAction action)
{
	switch (action)
	{
	case CACudaAction::Allocation:
		return "Cuda Allocation Error:";
	case CACudaAction::Free:
		return "Cuda Free Error:";
	case CACudaAction::HostCopy:
		return "Device -> Host Copy Error:";
	case CACudaAction::DeviceCopy:
		return "Host -> Device Copy Error:";
	case CACudaAction::Memset:
		return "Cuda Memset Error:";
	case CACudaAction::Reset:
		return "Cuda Reset Error:";
	case CACudaAction::SetDevice:
		return "Cuda Set Device Error:";
	case CACudaAction::GetProperty:
		return "Cuda Get Property Error:";
	case CACudaAction::GraphicsResourceMap:
		return "Graphics Resource Map Error:";
	case CACudaAction::GraphicsResourceUnmap:
		return "Graphics Resource Unmap Error:";
	default:
		return "";
	}
}

static cudaError_t CudaReportOnError(cudaError_t status, CACudaAction action, std::string customIdentifier = "", const std::function<void()>&actionOnError = const std::function<void()>(nullptr))
{
	if (status != cudaSuccess)
	{
		std::cout << CudaActionToString(action) << " " << customIdentifier << " " << cudaGetErrorString(status);
		if (actionOnError)
			actionOnError();
		if (action == CACudaAction::Allocation)
			exit(-1);
	}
	return status;
}
#endif
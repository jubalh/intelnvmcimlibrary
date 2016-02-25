/*
 * NvmProviderFactory.cpp
 *
 * Copyright 2015 Intel Corporation All Rights Reserved.
 *
 * INTEL CONFIDENTIAL
 *
 * The source code contained or described herein and all documents related to
 * the source code ("Material") are owned by Intel Corporation or its suppliers
 * or licensors. Title to the Material remains with Intel Corporation or its
 * suppliers and licensors. The Material may contain trade secrets and
 * proprietary and confidential information of Intel Corporation and its
 * suppliers and licensors, and is protected by worldwide copyright and trade
 * secret laws and treaty provisions. No part of the Material may be used,
 * copied, reproduced, modified, published, uploaded, posted, transmitted,
 * distributed, or disclosed in any way without Intel's prior express written
 * permission.
 *
 * No license under any patent, copyright, trade secret or other intellectual
 * property right is granted to or conferred upon you by disclosure or delivery
 * of the Materials, either expressly, by implication, inducement, estoppel or
 * otherwise. Any license under such intellectual property rights must be
 * express and approved by Intel in writing.
 *
 * Unless otherwise agreed by Intel in writing, you may not remove or alter this
 * notice or any other notice embedded in Materials by Intel or Intel's
 * suppliers or licensors in any way.
 */

#include "ProviderFactory.h"
#include "Strings.h"

namespace wbem
{
namespace framework
{

ProviderFactory *ProviderFactory::m_pSingleton = NULL;

ProviderFactory::ProviderFactory()
{
	// Child ProviderFactory is expected to override this
	setDefaultCimNamespace(INTEL_ROOT_NAMESPACE);
}

ProviderFactory::~ProviderFactory()
{
	if (this == m_pSingleton)
	{
		// We must be the singleton - set it to null before we go away
		m_pSingleton = NULL;
	}
}

ProviderFactory *ProviderFactory::getSingleton()
{
	return m_pSingleton;
}

void ProviderFactory::setSingleton(ProviderFactory* pProviderFactory)
{
	deleteSingleton();
	m_pSingleton = pProviderFactory;
}

void ProviderFactory::deleteSingleton()
{
	if (m_pSingleton)
	{
		delete m_pSingleton;
	}
}

std::string ProviderFactory::getDefaultCimNamespace()
{
	return m_defaultCimNamespace;
}

void ProviderFactory::setDefaultCimNamespace(const std::string& cimNamespace)
{
	 m_defaultCimNamespace = cimNamespace;
}

InstanceFactory* wbem::framework::ProviderFactory::getInstanceFactoryStatic(
		const std::string& className)
{
	InstanceFactory *pFactory = NULL;
	ProviderFactory *pSingleton = ProviderFactory::getSingleton();
	if (pSingleton)
	{
		pFactory = pSingleton->getInstanceFactory(className);
	}

	return pFactory;
}

std::vector<InstanceFactory *> ProviderFactory::getAssociationFactoriesStatic(
		Instance *pInstance,
		const std::string &associationClassName,
		const std::string &resultClassName,
		const std::string &roleName,
		const std::string &resultRoleName)
{
	std::vector<InstanceFactory *> associationFactories;
	ProviderFactory *pSingleton = ProviderFactory::getSingleton();
	if (pSingleton)
	{
		associationFactories = pSingleton->getAssociationFactories(
				pInstance,
				associationClassName, resultClassName,
				roleName, resultRoleName);
	}

	return associationFactories;
}


} /* namespace framework */
} /* namespace wbem */

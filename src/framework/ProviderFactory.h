/*
 * NvmProviderFactory.h
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

/*
 * This class serves as an abstract base class for a factory that creates
 * InstanceFactories for given CIM classes.
 */

#ifndef WBEM_FRAMEWORK_PROVIDERFACTORY_H_
#define WBEM_FRAMEWORK_PROVIDERFACTORY_H_

#include <string>
#include <vector>
#include "InstanceFactory.h"
#include "AssociationFactory.h"
#include "IndicationService.h"

namespace wbem
{
namespace framework
{

class ProviderFactory : public InstanceFactoryCreator
{
public:
	ProviderFactory();
	virtual ~ProviderFactory();

	/*
	 * Each provider is expected to set its singleton on library load. It is up to the
	 * provider to delete the singleton when the process is complete.
	 *
	 * Setting the singleton will cause the old singleton, if any, to be automatically
	 * deleted.
	 */
	static ProviderFactory *getSingleton();
	static void setSingleton(ProviderFactory *pProviderFactory);
	static void deleteSingleton();

	/*
	 * Fetches the default CIM namespace for this set of CIM providers.
	 */
	std::string getDefaultCimNamespace();

	/*
	 * Gets the singleton and fetches the appropriate InstanceFactory. Returns
	 * NULL if either singleton or factory is NULL.
	 */
	static InstanceFactory *getInstanceFactoryStatic(const std::string &className);

	/*
	 * Gets the singleton and fetches the appropriate InstanceFactories for associations.
	 * Returns empty list if either singleton or factory is NULL.
	 */
	static std::vector<InstanceFactory *> getAssociationFactoriesStatic(
			Instance *pInstance,
			const std::string &associationClassName,
			const std::string &resultClassName,
			const std::string &roleName,
			const std::string &resultRoleName);

	/*
	 * Implement this method to return an appropriate InstanceFactory for the given
	 * CIM class name.
	 */
	virtual InstanceFactory *getInstanceFactory(const std::string &className) = 0;

	/*
	 * Implement this method to return an appropriate AssociationFactory list
	 * for the request.
	 */
	virtual std::vector<InstanceFactory *> getAssociationFactories(
			Instance *pInstance,
			const std::string &associationClassName,
			const std::string &resultClassName,
			const std::string &roleName,
			const std::string &resultRoleName) = 0;

	virtual IndicationService *getIndicationService() = 0;

protected:
	static ProviderFactory *m_pSingleton;
	std::string m_defaultCimNamespace;

	/*
	 * Sets the default CIM namespace for this set of CIM providers.
	 */
	void setDefaultCimNamespace(const std::string &cimNamespace);
};

} /* namespace framework */
} /* namespace wbem */

#endif /* WBEM_FRAMEWORK_PROVIDERFACTORY_H_ */

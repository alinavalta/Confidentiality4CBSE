package edu.kit.kastel.scbs.pcm2prologxsb.generator

import edu.kit.ipd.sdq.mdsd.ecore2log.config.UserConfiguration
import edu.kit.kastel.scbs.confidentiality.ConfidentialitySpecification
import edu.kit.kastel.scbs.confidentiality.data.DataSet
import edu.kit.kastel.scbs.pcm2prologxsb.config.PCM2PrologXSBFilter
import edu.kit.kastel.scbs.pcm2prologxsb.config.PCMNameConfiguration
import edu.kit.kastel.scbs.pcm2prologxsb.config.PrologXSBLogConfiguration
import java.util.ArrayList
import java.util.Collection
import java.util.Collections
import java.util.Comparator
import java.util.List
import org.eclipse.core.resources.IFile
import org.eclipse.emf.common.util.BasicEList
import org.eclipse.emf.common.util.EList
import org.eclipse.emf.ecore.EAttribute
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.EStructuralFeature
import org.eclipse.emf.ecore.resource.Resource
import org.modelversioning.emfprofileapplication.StereotypeApplication
import org.palladiosimulator.pcm.core.composition.AssemblyConnector
import org.palladiosimulator.pcm.core.composition.AssemblyContext
import org.palladiosimulator.pcm.core.composition.Connector
import org.palladiosimulator.pcm.repository.OperationInterface
import org.palladiosimulator.pcm.repository.Parameter
import edu.kit.ipd.sdq.mdsd.ecore2log.generator.AbstractEcore2LogGenerator
import edu.kit.kastel.scbs.confidentiality.information.Information
import edu.kit.kastel.scbs.confidentiality.information.ParameterInformation
import edu.kit.kastel.scbs.confidentiality.information.ReturnValueInformation
import edu.kit.kastel.scbs.confidentiality.information.CallInformation
import edu.kit.kastel.scbs.confidentiality.information.SizeOfInformation
import edu.kit.kastel.scbs.confidentiality.resources.AbstractResourceProtection
import edu.kit.kastel.scbs.confidentiality.resources.LinkingResourceProtection
import edu.kit.kastel.scbs.confidentiality.resources.ResourceContainerProtection
import edu.kit.kastel.scbs.confidentiality.resources.ResourceContainerConfidentiality
import edu.kit.kastel.scbs.confidentiality.resources.Encryption
import java.util.Map
import java.util.Set
import edu.kit.kastel.scbs.confidentiality.information.AllInformation
import edu.kit.kastel.scbs.confidentiality.system.AbstractSpecificationParameterAssignement
import edu.kit.kastel.scbs.confidentiality.system.SpecificationParameterEquation
import edu.kit.kastel.scbs.confidentiality.adversary.Adversary
import edu.kit.kastel.scbs.confidentiality.repository.InterfaceInformationFlow
import edu.kit.kastel.scbs.confidentiality.repository.SignatureInformationFlow
import edu.kit.kastel.scbs.confidentiality.repository.InformationFlowParameter
import edu.kit.kastel.scbs.confidentiality.repository.AbstractInformationFlow
import edu.kit.kastel.scbs.confidentiality.system.DataSetMapParameter2KeyAssignment
import edu.kit.kastel.scbs.confidentiality.data.DataSetMapEntry

class PCM2PrologXSBGenerator extends AbstractEcore2LogGenerator<PCMNameConfiguration> {
	private val Map<EObject, Set<String>> resourceProtectionMap = newHashMap()
	private val Map<EObject, Set<String>> informationFlowMap = newHashMap()
	private val Map<EObject, Set<String>> informationInterfaceFlowMap = newHashMap()
	private val Map<EObject, Set<String>> informationFlowParameterAssignmentMap = newHashMap()
	private val Map<EObject, Set<String>> informationFlowParameterEquationMap = newHashMap()
	
	private val Set<String> processedInformationIds = newHashSet()
	
	new(UserConfiguration userConfiguration) {
		super(new PCM2PrologXSBFilter, new PCMNameConfiguration, new PrologXSBLogConfiguration, userConfiguration)
	}
	
	override getFolderNameForResource(Resource inputResource) {
		return "src-gen"
	}
	
	override getFileNameForResource(Resource inputResource) {
		return nameConfig.getFileName(inputResource) + "." + nameConfig.getFileExtension
	}
	
	override preprocessInputFiles(List<IFile> inputFiles) {
		return sortInputFiles(inputFiles)
	}
	
	override String generateAttributeValue(EObject e, Object attributeValue) {
		if (attributeValue == null) return logConfig.generateNullPlaceholder();
		val valString = attributeValue.toString();
		try {
			Integer.parseInt(valString)
			return valString
		} catch (NumberFormatException nfe) {
			if (nameConfig.isKeyword(valString)) {
				return valString
			} else {
				return "\"" + valString.replace("\"","\\\"") + "\""
			}
		}
		        
	}
	
	private def List<IFile> sortInputFiles(List<IFile> inputFiles) {
		val preprocessedInputFiles = new ArrayList(inputFiles.size)
		preprocessedInputFiles.addAll(inputFiles)	
		Collections.sort(preprocessedInputFiles, new Comparator<IFile>() {
			override compare(IFile o1, IFile o2) {
				val fileExtIndex1 = fileExt2Index(o1.fileExtension)
				val fileExtIndex2 = fileExt2Index(o2.fileExtension)
				return fileExtIndex1.compareTo(fileExtIndex2)
			}
			
			def private int fileExt2Index(String fileExt) {
				switch fileExt {
					case 'confidentiality' : 0
					case 'adversary' : 1
					case 'repository' : 2
					case 'system' : 3
					case 'resourceenvironment' : 4
					case 'allocation' : 5
					default : 6
				}
			}
		})
		return preprocessedInputFiles
	}
	
	override String generateMainContent(EList<EObject> firstLevelContents) {
		var mainContent = super.generateMainContent(firstLevelContents) 
		if(!firstLevelContents.filter[c | c instanceof ConfidentialitySpecification].empty) {
			return mainContent + generatePredicateFormMap(resourceProtectionMap, nameConfig.locationsAndTamperProtections_Reference, nameConfig.locationsAndTamperProtections_predicate) 
					 		   + generatePredicateFormMap(informationFlowMap,nameConfig.parameterAndDataPair_Reference, nameConfig.informationFlow_predicate)
					 		   + generatePredicateFormMap(informationInterfaceFlowMap,nameConfig.parameterAndDataPair_Reference, nameConfig.informationFlow_predicate)
					 		   + generatePredicateFormMap(informationFlowParameterAssignmentMap, nameConfig.inforamtionFlowParameter_Reference, nameConfig.inforamtionFlowParameter_predicate)
					 		   + generatePredicateFormMap(informationFlowParameterEquationMap, nameConfig.informationFlowEquation_Reference, nameConfig.informationFlowEquation_predicate)
		}
		return mainContent
		
	}
	
	override generateDeeply(EObject e) {
		return generateDeeplyCorrectly(e)
	}
	
	override generateFeatures(EObject e) {
		var features = ""
		for (relevantFeature : e.eClass.EAllStructuralFeatures.filter[a | relevantFeatureFor(a,e)]) {
			features += generateFeature(e, relevantFeature)
		}
		return super.generateFeatures(e)
	}
	private def String generatePredicateFormMap(Map<EObject,Set<String>> map, String predicateName, String desciptionEntityName) {
		var String content = ""
		for(entry : map.entrySet()) {
			var instanceCommentOpening = ""
			var instanceCommentClosing = ""
			var newLine = ""
			if (userConfig.generateComments) {
				instanceCommentOpening = generateInstanceCommentOpening(entry.key)
				instanceCommentClosing = generateInstanceCommentClosing(entry.key)
				newLine = generateNewLine()
			}
			var instanceDescriptionPredicate = ""
			if (userConfig.generateDescriptions) {
				instanceDescriptionPredicate = generateInstanceDescriptionPredicate(entry.key, desciptionEntityName)
			}
			val id = generateID(entry.key)
			val values = concatAndFilterFeatureValue(entry.value.toList())
			content += newLine + instanceCommentOpening + instanceDescriptionPredicate + generateRelation(predicateName, id ,values) + instanceCommentClosing
		}	
		return content
		
	}
	
	def String generateInstanceDescriptionPredicate(EObject e, String instanceName) {
		val name = generateName(e)?.replace("'"," ")
		return generateRelation(nameConfig.descriptionPredicateName, generateID(e), #["'" + name + "'", "'" + instanceName + "'" ])
	} 
	
	def dispatch String generateDeeplyCorrectly(EObject e) {
		return super.generateDeeply(e)
	}
	
	def dispatch String generateDeeplyCorrectly(Parameter p) {
		val parameterPredicate = super.generateDeeply(p)
		val sizeOfId = getSizeOfId(p.parameterName)
		val predicateName = "sizeOf" + nameConfig.getInstanceName(p).toFirstUpper
		val sizeOfParameterPredicate = generatePredicate(predicateName, sizeOfId)
		val relationName = "sizeOf"
		val value = generateID(p)
		val sizeOfRelation = generateRelation(relationName, sizeOfId, value)
		return parameterPredicate + sizeOfParameterPredicate + sizeOfRelation
	}
	
	dispatch def String generateDeeplyCorrectly(AbstractResourceProtection rp) {
		var instanceCommentOpening = ""
		var instanceCommentClosing = ""
		val predicateName = nameConfig.locationsAndTamperProtections_predicate
		
		var newLine = ""
		if (userConfig.generateComments) {
			instanceCommentOpening = generateInstanceCommentOpening(rp)
			instanceCommentClosing = generateInstanceCommentClosing(rp)
			newLine = generateNewLine()
		}
		val instancePredicate = generatePredicate(predicateName, generateID(rp))
		var instanceDescriptionPredicate = ""
		if (userConfig.generateDescriptions) {
			instanceDescriptionPredicate = generateInstanceDescriptionPredicate(rp)
		}
		val features = generateFeatures(rp)
		val children = generateChildren(rp)
		
		if(rp instanceof LinkingResourceProtection) {
			for(linkingResource : (rp as LinkingResourceProtection).linkingResource) {
				addToMapValuedMap(resourceProtectionMap, linkingResource, generateID(rp))
			}
		} else if(rp instanceof ResourceContainerProtection) {
			for(resourceContainer : (rp as ResourceContainerProtection).resourceContainer) {
				addToMapValuedMap(resourceProtectionMap, resourceContainer, generateID(rp))
			}
		}		
		return newLine + instanceCommentOpening + instanceDescriptionPredicate + instancePredicate + features + children + instanceCommentClosing + newLine
	}
	
	dispatch def String generateDeeplyCorrectly(ResourceContainerConfidentiality rc) {
		var instanceCommentOpening = ""
		var instanceCommentClosing = ""
		var newLine = ""
		if (userConfig.generateComments) {
			instanceCommentOpening = generateInstanceCommentOpening(rc)
			instanceCommentClosing = generateInstanceCommentClosing(rc)
			newLine = generateNewLine()
		}
		
		//Sharing
		val sharingFeatureName = nameConfig.sharingType_predicate
		val featureValueSharing = generateFeatureValues(rc, rc.eClass.getEStructuralFeature(nameConfig.sharingType_Reference))
		//FurtherConnections
		val connectionTypeFeatureName = nameConfig.connectionType_predicate
		val featureValueConnectionType = generateFeatureValues(rc, rc.eClass.getEStructuralFeature(nameConfig.connectionType_Reference))
		
		var content =  newLine + instanceCommentOpening
		for(resourceContainer : rc.appliedTo) {
			var instanceDescriptionPredicateSharing = ""
			var instanceDescriptionPredicateConnection = ""
			val id = generateID(resourceContainer)
			if (userConfig.generateDescriptions) {
				instanceDescriptionPredicateSharing = generateInstanceDescriptionPredicate(resourceContainer, sharingFeatureName)
				instanceDescriptionPredicateConnection = generateInstanceDescriptionPredicate(resourceContainer, connectionTypeFeatureName)
			}
			//Sharing
			content += instanceDescriptionPredicateSharing + sharingFeatureName + logConfig.generatePredicateOpening + id + logConfig.generatePredicateSeparator + featureValueSharing + logConfig.generatePredicateClosing
			//FurtherConnections
			content += instanceDescriptionPredicateConnection + connectionTypeFeatureName + logConfig.generatePredicateOpening + id + logConfig.generatePredicateSeparator + featureValueConnectionType + logConfig.generatePredicateClosing
		}			
		return content +  instanceCommentClosing + newLine
	}
	
	dispatch def String generateDeeplyCorrectly(Encryption ec) {
		var instanceCommentOpening = ""
		var instanceCommentClosing = ""
		var newLine = ""
		if (userConfig.generateComments) {
			instanceCommentOpening = generateInstanceCommentOpening(ec)
			instanceCommentClosing = generateInstanceCommentClosing(ec)
			newLine = generateNewLine()
		}
		
		val featureName = nameConfig.encryption_predicate
		val descriptionName = nameConfig.encryption_description
		val featureValueSharing = generateFeatureValues(ec, ec.eClass.getEStructuralFeature(featureName))
		var instanceDescriptionPredicate = ""
		if (userConfig.generateDescriptions) {
			instanceDescriptionPredicate = generateInstanceDescriptionPredicate(ec, descriptionName)
		}
		var content =  newLine + instanceCommentOpening
		for(linkingResource : ec.appliedTo) {
			content += instanceDescriptionPredicate + featureName + logConfig.generatePredicateOpening + generateID(linkingResource) + logConfig.generatePredicateSeparator + featureValueSharing + logConfig.generatePredicateClosing
		}			
		return content +  instanceCommentClosing + newLine
	}

	dispatch def String generateDeeplyCorrectly(AbstractInformationFlow ifl) {
		var instanceCommentOpening = ""
		var instanceCommentClosing = ""
		var newLine = ""
		if (userConfig.generateComments) {
			instanceCommentOpening = generateInstanceCommentOpening(ifl)
			instanceCommentClosing = generateInstanceCommentClosing(ifl)
			newLine = generateNewLine()
		}
		
		val featureName = nameConfig.parameterAndDataPair_predicate
		val parameterSourcesName =nameConfig.parameterSources_Reference
		var content = ""
		for(information : ifl.information) {
			val id = generateID(information)
			//Work around for Information instance with same Id
			if(!processedInformationIds.contains(id)) {
				processedInformationIds.add(id)
				val parameterSourceList = concatAndFilterFeatureValue(#[generateInformationFeatureValue(information)])
				var instanceDescriptionPredicate = ""
				if (userConfig.generateDescriptions) {
					instanceDescriptionPredicate = generateInstanceDescriptionPredicate(information, featureName)
				}
				content += instanceDescriptionPredicate + generatePredicate(featureName, id) + generateRelation(parameterSourcesName, id, parameterSourceList) + generateFeatures(information)
			}
			addInformationToMap(ifl, id)
		}
		
		return instanceCommentOpening + content +  instanceCommentClosing + newLine
	}
	
	private def void addInformationToMap(AbstractInformationFlow ifl, String informationId) {
		//Fill map
		if(ifl instanceof InterfaceInformationFlow) {
			for(signature : ifl.appliedTo.signatures__OperationInterface) {
				addToMapValuedMap(informationInterfaceFlowMap, signature, informationId)
			}
		} else if(ifl instanceof SignatureInformationFlow) {
			addToMapValuedMap(informationFlowMap, ifl.appliedTo, informationId)
		}	
	}
	
	def dispatch String generateDeeplyCorrectly(InformationFlowParameter ip) {
		var instanceCommentOpening = ""
		var instanceCommentClosing = ""
		var newLine = ""
		if (userConfig.generateComments) {
			instanceCommentOpening = generateInstanceCommentOpening(ip)
			instanceCommentClosing = generateInstanceCommentClosing(ip)
			newLine = generateNewLine()
		}
		//Interface or Signature ID		 
		val informationFlow = ip.informationFlow
		var id = ""
		if(informationFlow instanceof InterfaceInformationFlow) {
			id = generateID(informationFlow.appliedTo)
		} else if(informationFlow instanceof SignatureInformationFlow) {
			id = generateID(informationFlow.appliedTo)
		} else {
			return ""
		}
		
		var features = ""
		for (relevantFeature : ip.eClass.EAllStructuralFeatures.filter[a | relevantFeatureFor(a,ip)]) {
			features += generateFeatureWithOtherId(ip, relevantFeature, id)
		}
		return newLine + instanceCommentOpening + features + instanceCommentClosing
	}
	
	private def String generateFeatureWithOtherId(EObject e, EStructuralFeature feature, String id) {
		if (!feature.transient) {
			val predicateName = nameConfig.getFeatureName(e, feature) 
			val featureValues = generateFeatureValues(e, feature)
			val filteredFeatureValues = concatAndFilterFeatureValue(featureValues)
			return generateRelation(predicateName, id, filteredFeatureValues)
		}
		return ""
	}
	 
	def dispatch private String generateInformationFeatureValue(ParameterInformation information) {
		return generateID(information.appliedTo)
	}
	
	def dispatch private String generateInformationFeatureValue(ReturnValueInformation information) {
		return nameConfig.returnAtom
	}
	
	def dispatch private String generateInformationFeatureValue(CallInformation information) {
		return nameConfig.callAtom
	}
	
	def dispatch private String generateInformationFeatureValue(AllInformation information) {
		return nameConfig.wildCardAtom
	}
	def dispatch private String generateInformationFeatureValue(SizeOfInformation sizeOfInformation) {
		return nameConfig.sizeOf(generateInformationFeatureValue(sizeOfInformation.information))
	}

	override String generateFeature(EObject e, EStructuralFeature feature) {
		return generateFeatureCorrectly(e,feature)
	}
	
	def dispatch String generateFeatureCorrectly(EObject e, EStructuralFeature feature) {
		return super.generateFeature(e,feature)
	}
	
	def dispatch  String generateFeatureCorrectly(AbstractSpecificationParameterAssignement sa, EReference reference) {
		if(reference.name.equals("assignedByConnector")) {
			val id = generateID(sa)
			for(connector : sa.assignedByConnector) {
				informationFlowParameterAssignmentMap.addToMapValuedMap(connector, id)
			}
			return ""
		}
		return super.generateFeature(sa,reference)
	}
	
	def dispatch  String generateFeatureCorrectly(SpecificationParameterEquation se, EReference reference) {
		if(reference.name.equals("assignedByContext")) {
			val id = generateID(se)
			for(context : se.assignedByContext) {
				informationFlowParameterEquationMap.addToMapValuedMap(context, id)
			}
			return ""
		}
		return super.generateFeature(se,reference)
	}
	
	def dispatch String generateFeatureCorrectly(Adversary adversary, EReference reference) {
		if(reference.name.equals(nameConfig.mayTamperWith_Reference)) {
			val predicateName = nameConfig.locationsAndTamperProtections_Reference
			val id = generateID(adversary)
			val featureValues = generateFeatureValues(adversary, reference)
			val filteredFeatureValues = concatAndFilterFeatureValue(featureValues)
			return generateRelation(predicateName, id, filteredFeatureValues)
		}
		return super.generateFeature(adversary, reference)
	}
	
	override generateFeatureValues(EObject e, EStructuralFeature feature) {
		return generateFeatureValuesCorrectly(e, feature)
	}

	def dispatch List<String> generateFeatureValuesCorrectly(EObject e, EStructuralFeature feature) {
		return super.generateFeatureValues(e, feature)
	}
	
	def dispatch List<String> generateFeatureValuesCorrectly(DataSetMapEntry e, EReference reference) {
		val userIdentifierName = nameConfig.userIdentifier_Reference
		if(reference.name.equals(userIdentifierName)) {
			return #[e.userIdentifiers.entityName]
		}
		return super.generateFeatureValues(e, reference)
	}
	
	def dispatch List<String> generateFeatureValuesCorrectly(DataSetMapParameter2KeyAssignment e, EReference reference) {
		val userIdentifierName = nameConfig.assignedKey_Reference
		if(reference.name.equals(userIdentifierName)) {
			return #["\"" + e.assignedKey.entityName + "\""]
		}
		return super.generateFeatureValues(e, reference)
	}
	
	def dispatch List<String> generateFeatureValuesCorrectly(ConfidentialitySpecification sp, EReference reference) {
		val referenceName = nameConfig.informationFlow_Reference
		if(reference.name.equals(referenceName)) {
			var list = newHashSet()
			for(iflow : sp.informationFlows) {
				list.addAll(iflow.information.map[t | generateID(t)])
			}
			return list.toList
		}
		return super.generateFeatureValues(sp, reference)
	}
	
	private def String getSizeOfId(String parameterName) {
		var sizeOfId = "sizeOf_" + parameterName + "_"
		if (userConfig.simplifyIDs) {
			sizeOfId = nameConfig.getSimpleIDValue(sizeOfId)?.toString
		}
		return sizeOfId
	}
	
	def static private <K,V> void addToMapValuedMap(Map<K,Set<V>> firstMap, K firstKey, V value) {
			var secondMap = firstMap.get(firstKey)
			if (secondMap === null) {
				secondMap = newHashSet()
				firstMap.put(firstKey, secondMap)
			}
			secondMap.add(value)
		}
}
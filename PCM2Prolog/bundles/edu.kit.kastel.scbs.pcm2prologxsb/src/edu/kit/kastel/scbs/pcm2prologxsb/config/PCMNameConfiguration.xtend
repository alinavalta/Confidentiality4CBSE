package edu.kit.kastel.scbs.pcm2prologxsb.config

import edu.kit.ipd.sdq.mdsd.ecore2log.config.DefaultMetamodel2LogNameConfiguration
import org.eclipse.emf.ecore.EAttribute
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EStructuralFeature
import org.palladiosimulator.pcm.core.entity.NamedElement
import org.palladiosimulator.pcm.repository.Parameter
import org.palladiosimulator.pcm.repository.PrimitiveDataType
import org.palladiosimulator.pcm.resourceenvironment.ResourceEnvironment
import edu.kit.kastel.scbs.confidentiality.resources.SharingType
import edu.kit.kastel.scbs.confidentiality.resources.ConnectionType

class PCMNameConfiguration extends DefaultMetamodel2LogNameConfiguration {
	override getFileExtension() {
		return "P"
	}
	
	override getFeatureName(EObject object, EStructuralFeature feature) {
		val renameFeatureWhiteList = #{
			'resourceProtections' -> 'locationsAndTamperProtectionsPairs',
			'informationFlows' -> 'parametersAndDataPairs',
			'entityName' -> 'nameFor'
		}
		var featureName = super.getFeatureName(object, feature)
		if(renameFeatureWhiteList.containsKey(featureName)) {
			featureName = renameFeatureWhiteList.get(featureName)
		}
		
		if (featureName != null) {
			val indexOfFirstUnderline = featureName.indexOf("_")
			if (indexOfFirstUnderline > -1) {
				val keepOriginalFeatureNameSet = #{ 'assemblyContext_AllocationContext' }
				if (keepOriginalFeatureNameSet.contains(featureName)) {
					return featureName
				} else {
					return featureName.substring(0,indexOfFirstUnderline)
				}
			}
		}
		return featureName
	}
	
	override getNameValue(EObject e) {
		return getCorrectNameValue(e)
	}
	
	def dispatch private String getCorrectNameValue(EObject e) {
		return super.getNameValue(e)
	}
	
	def dispatch private String getCorrectNameValue(NamedElement ne) {
		return ne.entityName
	}
	
	def dispatch private String getCorrectNameValue(Parameter p) {
		return p.parameterName
	}
	
	override getIDReplacement(EObject e) {
		return getIDOrReplacement(e)
	}
	
	def dispatch String getIDOrReplacement(EObject e) {
		return super.getIDReplacement(e)
	}
	
	def dispatch String getIDOrReplacement(ResourceEnvironment resourceEnvironment) {
		return resourceEnvironment.entityName
	}
	
	def dispatch String getIDOrReplacement(PrimitiveDataType pdt) {
		return "\"" + pdt.getType().getName + "\""
	}
	
	def dispatch String getIDOrReplacement(Parameter p) {
		val signature = p.operationSignature__Parameter
		val signatureIDAttribute = getIDAttribute(signature)
		val signatureID = signature.eGet(signatureIDAttribute)
		val parameterID = signatureID + "-" + p.parameterName
		//return parameterID
		return p.parameterName
	}
	
	public val returnAtom = "return"
	
	public val callAtom = "call"
	
	public val wildCardAtom = "*"
	
	public val locationsAndTamperProtections_Reference = 'locationsAndTamperProtectionsPairs'
	public val locationsAndTamperProtections_predicate = 'locationsAndTamperProtectionsPair'
	public val informationFlow_predicate = 'informationFlow'
	public val informationFlow_Reference = 'informationFlows'
	public val parameterSources_Reference = 'parameterSources'
	public val parameterAndDataPair_Reference = 'parametersAndDataPairs'
	public val parameterAndDataPair_predicate = 'parametersAndDataPair'
	public val mayTamperWith_Reference = 'mayTamperWith'
	public val assignedKey_Reference = 'assignedKey'
	public val userIdentifier_Reference = 'userIdentifiers'
	public val sharingType_Reference = 'sharingType'
	public val sharingType_predicate = 'sharing'
	public val connectionType_Reference = 'connectionType'
	public val connectionType_predicate = 'connectionType'
	public val inforamtionFlowParameter_Reference = 'assignments'
	public val inforamtionFlowParameter_predicate = 'assignment'
	public val informationFlowEquation_Reference = 'equations'
	public val informationFlowEquation_predicate = 'equation'
	public val encryption_description = 'encryption'
	public val encryption_predicate = 'unencryptedData'
	
	
	public def String sizeOf(String value) {
		return "sizeOf(" + value + ")"
	}
	
	def boolean isKeyword(String value) {
		return isSharing(value) 
		    || isConnectionType(value)
	} 

	def boolean isSharing(String value) {
		return !SharingType.VALUES.filter[ s | s.literal.equals(value)].isEmpty
	} 
	
	def boolean isConnectionType(String value) {
		return !ConnectionType.VALUES.filter[ c | c.literal.equals(value)].isEmpty
	} 
}
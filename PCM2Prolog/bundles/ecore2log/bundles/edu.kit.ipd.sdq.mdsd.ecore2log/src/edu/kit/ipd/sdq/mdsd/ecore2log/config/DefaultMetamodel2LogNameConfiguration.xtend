package edu.kit.ipd.sdq.mdsd.ecore2log.config

import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EStructuralFeature
import org.eclipse.emf.ecore.resource.Resource
import java.util.Map
import java.util.HashMap
import org.eclipse.emf.ecore.EAttribute

class DefaultMetamodel2LogNameConfiguration implements Metamodel2LogNameConfiguration {
	// mapping from long and nasty IDs to sequential numbers
	val Map<Object,Integer> id2seqNumMap = new HashMap<Object,Integer>()
	var maxSeqNum = 0
	
	override getFileName(Resource input) {
		return input.URI.lastSegment
	}
	
	override getFileExtension() {
		return "L"
	}
	
	override getInstanceName(EObject e) {
		return e.eClass.name.toFirstLower
	}
	
	override getFeatureName(EObject object, EStructuralFeature feature) {
		return feature.name
	}
	
	override getSimpleIDValue(Object idValue) {
		var num = id2seqNumMap.get(idValue)
		if (num == null) {
			maxSeqNum += 1
			num = maxSeqNum
			id2seqNumMap.put(idValue,maxSeqNum)
		}
		return num
	}
	
	override getIDAttribute(EObject e) {
		return e.eClass.EIDAttribute
	}
	
	override replaceAttributeValueWithIDAttribute(EObject e, EAttribute attribute, Object attributeValue) {
		return false
	}
	
	override getNameValue(EObject e) {
		return null
	}
	
	override getIDReplacement(EObject e) {
		return e?.toString
	}
	
	
	override getDescriptionPredicateName() {
		return "description"
	}
	
}
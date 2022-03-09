package edu.kit.ipd.sdq.mdsd.ecore2log.config

import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EStructuralFeature

class DefaultMetamodel2LogFilter implements Metamodel2LogFilter {
	
	override relevantFirstLevelElement(EObject e) {
		return true
	}
	
	override relevantChild(EObject e) {
		return true
	}
		
	override onlyChildrenAreRelevant(EObject e) {
		return false
	}
	
	override relevantFeatureFor(EStructuralFeature feature, EObject e) {
		return true
	}
	
	override relevantFeatureValue(String featureValue) {
		return true
	}
	
	override relevantProfileNsURI(String profileNamespaceURI) {
		return true
	}
	
}
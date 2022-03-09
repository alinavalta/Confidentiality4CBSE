package edu.kit.ipd.sdq.mdsd.ecore2log.config

import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EStructuralFeature

interface Metamodel2LogFilter {
	def boolean relevantFirstLevelElement(EObject e)
	
	def boolean relevantChild(EObject e)
	
	def boolean onlyChildrenAreRelevant(EObject e)
	
	def boolean relevantFeatureFor(EStructuralFeature feature, EObject e)
	
	def boolean relevantFeatureValue(String featureValue)
	
	def boolean relevantProfileNsURI(String profileNamespaceURI)
}
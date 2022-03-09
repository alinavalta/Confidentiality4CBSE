package edu.kit.ipd.sdq.mdsd.ecore2log.config

import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EStructuralFeature
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.EAttribute

interface Metamodel2LogNameConfiguration {
	
	def String getFileName(Resource input)
	
	def String getFileExtension()
	
	def String getDescriptionPredicateName()
	
	def String getInstanceName(EObject e)
	
	def String getFeatureName(EObject e, EStructuralFeature feature)
	
	def Object getSimpleIDValue(Object idValue)
	
	def EAttribute getIDAttribute(EObject e)
	
	def boolean replaceAttributeValueWithIDAttribute(EObject e, EAttribute attribute, Object attributeValue)
	
	def String getNameValue(EObject e)
	
	def String getIDReplacement(EObject e)
	
}
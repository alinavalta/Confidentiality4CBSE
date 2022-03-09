package edu.kit.ipd.sdq.mdsd.ecore2log.config

import java.util.List
import org.eclipse.emf.ecore.EObject

interface LogConfiguration {
	def String generatePrelude(List<EObject> firstLevelContents)
	
	def String generatePostlude(List<EObject> firstLevelContents)
	
	def String generatePredicateOpening()
	
	def String generatePredicateSeparator()
	
	def String generatePredicateClosing()
	
	def String generateListOpening()
	
	def String generateListSeparator()
	
	def String generateListClosing()
	
	def String generateNullPlaceholder()
	
	def String generateCommentOpening()
	
	def String generateCommentClosing()
	
}
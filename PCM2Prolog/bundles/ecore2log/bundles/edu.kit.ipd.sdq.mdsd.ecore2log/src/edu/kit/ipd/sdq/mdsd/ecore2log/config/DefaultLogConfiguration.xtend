package edu.kit.ipd.sdq.mdsd.ecore2log.config

import edu.kit.ipd.sdq.mdsd.ecore2log.config.LogConfiguration
import org.eclipse.emf.ecore.EObject
import java.util.List

class DefaultLogConfiguration implements LogConfiguration {
		
	override generatePrelude(List<EObject> firstLevelContents) ''''''
	
	override generatePostlude(List<EObject> firstLevelContents) ''''''
	
	override generatePredicateOpening() '''('''
	
	override generatePredicateSeparator() ''','''
	
	override generatePredicateClosing() ''').
	'''
	
	override generateListOpening() '''['''
	
	override generateListSeparator() ''','''
	
	override generateListClosing() ''']'''
	
	override generateNullPlaceholder() '''null'''
	
	override generateCommentOpening() '''/** '''
	
	override generateCommentClosing() ''' */
	'''
}
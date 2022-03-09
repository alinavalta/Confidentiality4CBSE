package edu.kit.ipd.sdq.mdsd.ecore2log.generator

import edu.kit.ipd.sdq.mdsd.ecore2txt.generator.AbstractEcore2TxtGenerator
import edu.kit.ipd.sdq.mdsd.ecore2log.config.DefaultLogConfiguration
import edu.kit.ipd.sdq.mdsd.ecore2log.config.LogConfiguration
import edu.kit.ipd.sdq.mdsd.ecore2log.config.Metamodel2LogFilter
import edu.kit.ipd.sdq.mdsd.ecore2log.config.Metamodel2LogNameConfiguration
import edu.kit.ipd.sdq.mdsd.ecore2log.config.UserConfiguration
import java.io.BufferedReader
import java.io.StringReader
import java.util.ArrayList
import java.util.Collections
import java.util.HashMap
import java.util.LinkedList
import org.eclipse.emf.common.util.EList
import org.eclipse.emf.ecore.EAttribute
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.EStructuralFeature
import org.eclipse.emf.ecore.resource.Resource
import java.util.List

import static extension edu.kit.ipd.sdq.commons.util.java.lang.IterableUtil.mapFixed
import org.eclipse.internal.xtend.util.Triplet
import org.modelversioning.emfprofileapplication.StereotypeApplication

public abstract class AbstractEcore2LogGenerator<N extends Metamodel2LogNameConfiguration> extends AbstractEcore2TxtGenerator {
    val Metamodel2LogFilter mm2LogFilter
	val N nameConfig
	val LogConfiguration logConfig
	val UserConfiguration userConfig
	
	new(Metamodel2LogFilter mm2LogGenerator, N nameConfiguration, UserConfiguration userConfiguration) {
		this(mm2LogGenerator, nameConfiguration, new DefaultLogConfiguration(), userConfiguration)
	}
	
	new(Metamodel2LogFilter mm2LogGenerator, N nameConfiguration, LogConfiguration logConfiguration, UserConfiguration userConfiguration) {
		this.mm2LogFilter = mm2LogGenerator
		this.nameConfig = nameConfiguration
		this.logConfig = logConfiguration
		this.userConfig = userConfiguration
	}
	
	def protected Metamodel2LogFilter getMm2LogFilter() {
		return mm2LogFilter
	}
	
	def protected N getNameConfig() {
		return nameConfig
	}
	
	def protected LogConfiguration getLogConfig() {
		return logConfig
	}
	
	def protected UserConfiguration getUserConfig() {
		return userConfig	
	}
	
	override generateContentsFromResource(Resource inputResource) {
		val contentsForFolderAndFileNames = new ArrayList<Triplet<String,String,String>>()
		val fileName = getFileNameForResource(inputResource)
		val folderName = getFolderNameForResource(inputResource)
		val content = generateContent(inputResource)
		val postProcessedContents = postProcessGeneratedContents(content)
		val contentForFolderAndFileName = new Triplet<String,String,String>(postProcessedContents,folderName,fileName)
		contentsForFolderAndFileNames.add(contentForFolderAndFileName)
		contentsForFolderAndFileNames.addAll(generateAdditionalContentsForURIs(inputResource))
		return contentsForFolderAndFileNames
	}
	
	/**
	 * @return an iterable of pairs of additional generated contents and file names
	 */
	def Iterable<Triplet<String,String,String>> generateAdditionalContentsForURIs(Resource input) {
		return Collections.emptyList
	}
	
	override String postProcessGeneratedContents(String contents) {
		if (userConfig.groupFacts) {
			val rdr = new BufferedReader(new StringReader(contents));
	        var line = rdr.readLine()
	        val facts = new HashMap()
	        // Since there may be predicates with the same name but different arities (e.g.: "resourceContainer(22,24)." and "resourceContainer(24)."),
	        // we cannot group facts simply by sorting them.
	        // Instead, we attempt a rudimentary parsing of the lines, determining predicate name and arity. 
	        while (line != null ) {
	        	if (!line.equals("")) {
	        		val parser = new PrologFactParser(line)
	        		val fact  = parser.parseFact()
	        		
	        		if (!fact.toString().replace(" ", "").equals(line.replace(" ", ""))) {
	        			throw new AssertionError("Invalid parse \"" + fact.toString() + "\" for \"" + fact + "\"")
	        		}
	        		
	        		val predicateName = fact.getAtom()
	        		val argnr = fact.getArgs.size()
		        	val predicate = new Pair(predicateName,argnr)
		        	facts.putIfAbsent(predicate, new LinkedList<String>)
		        	facts.get(predicate).add(line);
		        }
		        line = rdr.readLine()
		    }
			rdr.close()
			val grouped = facts.values.map[
				it.add("") // make sure the last line is followed by a lineSeperator, aswell 
				it.join(System.lineSeparator)
			].join(System.lineSeparator)
			return grouped
		} else {
			return contents
		}
	}
	
	def String generateContent(Resource input) {
		val firstLevelContents = input.contents
		val prelude = logConfig.generatePrelude(firstLevelContents)
		val mainContent = generateMainContent(firstLevelContents)
		val postlude = logConfig.generatePostlude(firstLevelContents)
		return prelude+mainContent+postlude
	}
	
	def String generateMainContent(EList<EObject> firstLevelContents) {
		val builder = new StringBuilder
		for(relevantFirstLevelElement : firstLevelContents.filter[e | mm2LogFilter.relevantFirstLevelElement(e)]) {
			builder.append(generateDeeply(relevantFirstLevelElement))
		}
		return builder.toString
	}
	
	def String generateDeeply(EObject e) {
		var instanceCommentOpening = ""
		var instanceCommentClosing = ""
		var newLine = ""
		if (userConfig.generateComments) {
			instanceCommentOpening = generateInstanceCommentOpening(e)
			instanceCommentClosing = generateInstanceCommentClosing(e)
			newLine = generateNewLine()
		}
		val instancePredicate = generateInstancePredicate(e)
		var instanceDescriptionPredicate = ""
		if (userConfig.generateDescriptions) {
			instanceDescriptionPredicate = generateInstanceDescriptionPredicate(e)
		}
		val features = generateFeatures(e)
		val children = generateChildren(e)
		return newLine + instanceCommentOpening + instanceDescriptionPredicate + instancePredicate + features + children + instanceCommentClosing + newLine
	}
	
	def String generateInstanceCommentOpening(EObject e) {
		return generateInstanceComment(e, "BEGIN")
	}
	
	def String generateInstanceComment(EObject e, String marker) {
		return logConfig.generateCommentOpening() + marker + " " + nameConfig.getInstanceName(e) + ", ID: '" + generateID(e) + "', NAME: '" + generateName(e) + "'" + logConfig.generateCommentClosing()
	}
		
	def String generateInstanceCommentClosing(EObject e) {
		return generateInstanceComment(e, "END")
	}
	
	def String generateNewLine() '''

	'''
	
	def String generateInstancePredicate(EObject e) {
		if (!mm2LogFilter.onlyChildrenAreRelevant(e)) {
			val predicateName = nameConfig.getInstanceName(e) 
			val id = generateID(e)
			return generatePredicate(predicateName, id)
		}
		return ""
	}
	
	def String generateInstanceDescriptionPredicate(EObject e) {
		val name = generateName(e)?.replace("'"," ")
		val instanceName = nameConfig.getInstanceName(e)?.replace("'", " ")
		return generateRelation(nameConfig.descriptionPredicateName, generateID(e), #["'" + name + "'", "'" + instanceName + "'" ])
	}
	
	def String generateID(EObject e) {
		if (e instanceof StereotypeApplication) {
			val sa = e as StereotypeApplication
			return generateID(sa.appliedTo)
		}	
		
		val idAttribute = nameConfig.getIDAttribute(e)
		if (idAttribute == null) {
			val replacementValue = generateIDReplacement(e)
			return generateIDValue(e, replacementValue)
		}
		else {
			return generateIDValue(e, idAttribute)
		}
	}
	
	def String generateIDReplacement(EObject e) {
		var idReplacement = nameConfig.getIDReplacement(e)
		if (idReplacement == null) {
			// FIXME MK warn 
		} else 
		return idReplacement
	}
	
	def String generateIDValue(EObject e, EAttribute attribute) {
		val attributeValue = e.eGet(attribute)
		return generateIDValue(e, attributeValue)
	}
	
	def String generateIDValue(EObject e, Object idValue) {
		var configuredIdValue = idValue
		if (userConfig.simplifyIDs) {
			configuredIdValue = nameConfig.getSimpleIDValue(idValue)
		}
		return generateAttributeValue(e, configuredIdValue)
	}
	
	def String generateName(EObject e) {
		return nameConfig.getNameValue(e)
	}
		
	def String generateFeatures(EObject e) {
		var features = ""
		for (relevantFeature : e.eClass.EAllStructuralFeatures.filter[a | relevantFeatureFor(a,e)]) {
			features += generateFeature(e, relevantFeature)
		}
		return features
	}
	
	def boolean relevantFeatureFor(EStructuralFeature feature, EObject e) {
		if (feature instanceof EAttribute && ((feature as EAttribute).isID)) {
			return false
		} else {
			return mm2LogFilter.relevantFeatureFor(feature, e)
		}
	}
	
	def String generateFeature(EObject e, EStructuralFeature feature) {
		if (!feature.transient) {
			val predicateName = nameConfig.getFeatureName(e, feature) 
			val id = generateID(e)
			val featureValues = generateFeatureValues(e, feature)
			val filteredFeatureValues = concatAndFilterFeatureValue(featureValues)
			return generateRelation(predicateName, id, filteredFeatureValues)
		}
		return ""
	}
	
	def String generatePredicate(String predicateName, String id) {
		return generateRelation(predicateName, id, "")
	}
	
	def String generateRelation(String predicateName, String id, String value) {
		var content = predicateName + logConfig.generatePredicateOpening + id
		if (!value?.equals("")) {
			content += logConfig.generatePredicateSeparator + value
		} 
		content += logConfig.generatePredicateClosing
	}
	
	def String generateRelation(String predicateName, String id, List<String> values) {
		var content = predicateName + logConfig.generatePredicateOpening + id
		for (String value : values) {
			content += logConfig.generatePredicateSeparator + value
		}
		content += logConfig.generatePredicateClosing
	}
	
//	def dispatch String generateFeatureValues(EObject e, Void n) {
//		System.out.println("WARNING: null feature for EObject " + e);
//		return ""
//	}

	def String concatAndFilterFeatureValue(List<String> featureValues) '''«logConfig.generateListOpening»«FOR elem : featureValues.filter[mm2LogFilter.relevantFeatureValue(it)] SEPARATOR logConfig.generateListSeparator»«elem»«ENDFOR»«logConfig.generateListClosing»'''
	
	
	def List<String> generateFeatureValues(EObject e, EStructuralFeature feature) {
		if (feature.many) {
			return generateManyFeatureValues(e, feature)
		} else {
			return #[generateSingleFeatureValue(e, feature)]
		}
	}
	
	def List<String> generateManyFeatureValues(EObject e, EStructuralFeature feature) {
		val values = e.eGet(feature) as EList<?>
		return generateManyFeatureValues(e, feature, values)
	}
	
	def List<String> generateManyFeatureValues(EObject e, EStructuralFeature feature, EList<?> values) {
		return values.mapFixed[generateSingleFeatureValue(e, feature, it)]
	}
	
	def String generateSingleFeatureValue(EObject e, EStructuralFeature feature) {
		val value = e.eGet(feature)
		return generateSingleFeatureValue(e, feature, value)
	}
	
	def dispatch String generateSingleFeatureValue(EObject e, EStructuralFeature attribute, Void n) {
		logConfig.generateNullPlaceholder()
	}
		
	def dispatch String generateSingleFeatureValue(EObject e, EReference reference, EObject referencedEObject) {
		return if (mm2LogFilter.relevantChild(referencedEObject)) generateID(referencedEObject) else ""	
	}
	
	def dispatch String generateSingleFeatureValue(EObject e, EAttribute attribute, Object attributeValue) {
		if (nameConfig.replaceAttributeValueWithIDAttribute(e, attribute, attributeValue)) {
			return generateIDValue(e, attributeValue)
		} else {
			return generateAttributeValue(e, attributeValue)
		}
	}
	
	def String generateAttributeValue(EObject e, Object attributeValue) {
		return if (attributeValue == null) logConfig.generateNullPlaceholder() else attributeValue.toString
	}

	def String generateChildren(EObject e) {
		var children = ""
		for(relevantChild : e.eContents.filter[r | mm2LogFilter.relevantChild(r)]) {
			children += generateDeeply(relevantChild)
		}
		return children
	}
}
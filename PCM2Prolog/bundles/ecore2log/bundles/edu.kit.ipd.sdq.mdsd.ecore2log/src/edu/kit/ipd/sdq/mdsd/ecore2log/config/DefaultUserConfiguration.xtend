package edu.kit.ipd.sdq.mdsd.ecore2log.config

class DefaultUserConfiguration implements UserConfiguration {
	val boolean generateComments
	val boolean groupFacts
	val boolean simplifyIDs
	val boolean concatOutputToSingleFile
	val boolean generateDescriptions
	
	new() {
		this(true,false,true,false,false)
	}
	
	new(boolean generateComments, boolean groupFacts, boolean simplifyIDs, boolean concatOutputToSingleFile, boolean generateDescriptions) {
		this.generateComments = generateComments
		this.groupFacts = groupFacts
		this.simplifyIDs = simplifyIDs
		this.concatOutputToSingleFile = concatOutputToSingleFile
		this.generateDescriptions = generateDescriptions
	}
	
	override generateComments() {
		return generateComments
	}
	
	override groupFacts() {
		return groupFacts
	}
	
	override simplifyIDs() {
		return simplifyIDs
	}
	
	override concatOutputToSingleFile() {
		return concatOutputToSingleFile
	}

	override generateDescriptions() {
		return generateDescriptions
	}
	
}
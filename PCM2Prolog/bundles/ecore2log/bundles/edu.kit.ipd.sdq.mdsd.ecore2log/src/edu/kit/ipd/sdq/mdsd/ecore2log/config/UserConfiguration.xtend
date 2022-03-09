package edu.kit.ipd.sdq.mdsd.ecore2log.config

interface UserConfiguration {
	def boolean generateComments()
	def boolean groupFacts()
	def boolean simplifyIDs()
	def boolean concatOutputToSingleFile()
	def boolean generateDescriptions()
}
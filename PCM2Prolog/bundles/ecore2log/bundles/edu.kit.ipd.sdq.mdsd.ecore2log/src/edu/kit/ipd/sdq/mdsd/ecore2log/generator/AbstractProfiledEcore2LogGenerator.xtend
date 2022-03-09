package edu.kit.ipd.sdq.mdsd.ecore2log.generator

import edu.kit.ipd.sdq.mdsd.ecore2log.config.LogConfiguration
import edu.kit.ipd.sdq.mdsd.ecore2log.config.Metamodel2LogFilter
import edu.kit.ipd.sdq.mdsd.ecore2log.config.Metamodel2LogNameConfiguration
import edu.kit.ipd.sdq.mdsd.ecore2log.config.UserConfiguration
import java.util.ArrayList
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.resource.Resource
import org.modelversioning.emfprofileapplication.ProfileApplication
import org.modelversioning.emfprofileapplication.StereotypeApplication
import org.palladiosimulator.mdsdprofiles.api.ProfileAPI
import org.eclipse.internal.xtend.util.Triplet

abstract class AbstractProfiledEcore2LogGenerator<N extends Metamodel2LogNameConfiguration> extends AbstractEcore2LogGenerator<N> {
	
	new(Metamodel2LogFilter mm2LogGenerator, N nameConfiguration, LogConfiguration logConfiguration, UserConfiguration userConfiguration) {
		super(mm2LogGenerator, nameConfiguration, logConfiguration, userConfiguration)
	}
	
	override generateAdditionalContentsForURIs(Resource input) {
		val additionalContentsForURIs = new ArrayList<Triplet<String,String,String>>(1)
		if (ProfileAPI.hasProfileApplication(input)) {
			// FIXME MK ask Sebastian why there cannot be several PROFILE Applications
			val profileApplication = ProfileAPI.getProfileApplication(input)
			val profileImports = profileApplication?.importedProfiles
			for (profileImport : profileImports) {
				val profile = profileImport?.profile
				if (mm2LogFilter.relevantProfileNsURI(profile?.nsURI)) {
					val nsPrefix = profile.name
					val additionalContent = generateProfileApplicationContent(profileApplication)
					val fileURI = nameConfig.getFileName(input) + "." + nsPrefix + "." + nameConfig.getFileExtension
					val folderName = getFolderNameForResource(input)
					additionalContentsForURIs.add(new Triplet<String,String,String>(additionalContent,folderName,fileURI))
				}
			}
		}
		return additionalContentsForURIs
	}
	
	private def String generateProfileApplicationContent(ProfileApplication profileApplication) {
		val builder = new StringBuilder
		for (stereotypeApplication : profileApplication.stereotypeApplications) {
			builder.append(generateDeeply(stereotypeApplication))
		}
		return builder.toString
	}
	
	override generateIDReplacement(EObject e) {
		if (e instanceof StereotypeApplication) throw new IllegalArgumentException();
		super.generateIDReplacement(e)
	}
	
}
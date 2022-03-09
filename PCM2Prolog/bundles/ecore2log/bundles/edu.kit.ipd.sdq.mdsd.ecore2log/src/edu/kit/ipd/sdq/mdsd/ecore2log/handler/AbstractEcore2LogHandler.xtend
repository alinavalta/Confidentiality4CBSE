package edu.kit.ipd.sdq.mdsd.ecore2log.handler

import edu.kit.ipd.sdq.mdsd.ecore2txt.handler.AbstractEcoreIFile2TxtHandler
import edu.kit.ipd.sdq.mdsd.ecore2log.config.DefaultUserConfiguration
import edu.kit.ipd.sdq.mdsd.ecore2log.config.UserConfiguration
import org.eclipse.core.commands.ExecutionEvent
import org.eclipse.core.resources.IFile
import java.util.List

abstract class AbstractEcore2LogHandler extends AbstractEcoreIFile2TxtHandler {
	

	override executeEcore2TxtGenerator(List<IFile> files, ExecutionEvent event, String plugInID) {
		val generateComments = Boolean.parseBoolean(event.getParameter(plugInID + ".generateCommentsParameter"))
		val groupFacts = Boolean.parseBoolean(event.getParameter(plugInID + ".groupFactsParameter"))
		val simplifyIDs = Boolean.parseBoolean(event.getParameter(plugInID + ".simplifyIDsParameter"))
		val concatOutputToSingleFile = Boolean.parseBoolean(event.getParameter(plugInID + ".concatOutputToSingleFileParameter"))
		val generateDescriptions = Boolean.parseBoolean(event.getParameter(plugInID + ".generateDescriptions"))
		val userConfiguration = new DefaultUserConfiguration(generateComments, groupFacts, simplifyIDs, concatOutputToSingleFile, generateDescriptions)
		executeEcore2TxtGenerator(files, userConfiguration)
	}
	
	abstract def void executeEcore2TxtGenerator(List<IFile> files, UserConfiguration userConfiguration)
	
}
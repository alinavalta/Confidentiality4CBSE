package edu.kit.ipd.sdq.mdsd.ecore2log.config

import org.eclipse.emf.ecore.EObject
import org.modelversioning.emfprofileapplication.StereotypeApplication

class DefaultProfiledMetamodel2LogFilter extends DefaultMetamodel2LogFilter {
	 
	 override onlyChildrenAreRelevant(EObject e) {
		 if (e instanceof StereotypeApplication) {
			return true
		 }
		 return super.onlyChildrenAreRelevant(e)
	 }
}

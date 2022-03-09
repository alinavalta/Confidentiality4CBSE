package edu.kit.ipd.sdq.commons.util.org.palladiosimulator.pcm.core.composition

import org.palladiosimulator.pcm.core.composition.AssemblyConnector
import org.palladiosimulator.pcm.core.composition.Connector
import org.palladiosimulator.pcm.core.composition.ProvidedDelegationConnector
import org.palladiosimulator.pcm.core.composition.RequiredDelegationConnector
import org.palladiosimulator.pcm.repository.OperationInterface
import org.palladiosimulator.pcm.repository.OperationProvidedRole
import org.palladiosimulator.pcm.repository.OperationRequiredRole
import org.palladiosimulator.pcm.repository.Role
import static extension edu.kit.ipd.sdq.commons.util.org.palladiosimulator.pcm.repository.RoleUtil.*

/**
 * A utility class providing extension methods for connectors
 * 
 */
class ConnectorUtil {
	/** Utility classes should not have a public or default constructor. */
	private new() {
	}
	
	public static def OperationProvidedRole getOperationProvidedRole(Connector connector) {
		return getOperationRole(connector, true) as OperationProvidedRole
	}
	
	public static def OperationRequiredRole getOperationRequiredRole(Connector connector) {
		return getOperationRole(connector, false) as OperationRequiredRole
	}
	
	public static def Role getOperationRole(Connector connector, boolean providedNotRequired) {
		val connectedRole = switch connector {
			AssemblyConnector : if (providedNotRequired) connector?.providedRole_AssemblyConnector else connector?.requiredRole_AssemblyConnector
			ProvidedDelegationConnector : if (providedNotRequired) connector?.innerProvidedRole_ProvidedDelegationConnector else throw new RuntimeException("Cannot get required role for ProvidedDelegationConnector '" + connector + "'!")
			RequiredDelegationConnector : if (!providedNotRequired) connector?.innerRequiredRole_RequiredDelegationConnector else throw new RuntimeException("Cannot get provided role for RequiredDelegationConnector '" + connector + "'!")
		}
		return connectedRole
	}
	
	public static def OperationInterface getOperationInterface(Connector connector, boolean providedNotRequired) {
		val connectedRole = getOperationRole(connector, providedNotRequired)
		return getOperationInterface(connectedRole, providedNotRequired)
	}			
}
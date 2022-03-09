package edu.kit.ipd.sdq.commons.util.java

import org.eclipse.xtend.lib.annotations.Data

/**
 * A 4-tuple.
 *
 * @param <A>
 *            the type of the first element
 * @param <B>
 *            the type of the second element
 * @param <C>
 *            the type of the third element
 * @param <D>
 *            the type of the fourth element
 * @author Max E. Kramer
 */
 @Data
class Quadruple<A,B,C,D> extends Triple<A,B,C> {
	D fourth
	
    /**
     * @return the element at zero-based index 3, which is also available via the getter {@link D getFourth()}
     */
	def D get3() {
    	return fourth
    }
	
	override toString() '''Quadruple(«this.first»,«this.second»,«this.third»,«this.fourth»)'''
}
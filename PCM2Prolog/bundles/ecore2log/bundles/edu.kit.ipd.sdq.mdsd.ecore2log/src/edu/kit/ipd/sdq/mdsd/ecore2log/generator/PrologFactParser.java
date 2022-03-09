package edu.kit.ipd.sdq.mdsd.ecore2log.generator;

import java.util.Collections;
import java.util.LinkedList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

enum TokenType {
	EOF(null),
	LPAREN("\\("),
	RPAREN("\\)"),
	LSQUARE("\\["),
	RSQUARE("\\]"),
	COMMA(","),
	DOT("\\."),
	WHITESPACE("[ \t\n\r]"),
	ATOM("[^,\\(\\).\\[\\]]+", true);

	/**
	 * The regular expression matching character sequencing corresponding to this TokenType.
	 */
	public final String regexp;

	/**
	 * Shall token of this type remember the characters matched during lexing?
	 */
	public final boolean rememberCharacters;

	TokenType(String regexp, boolean rememberCharacters) {
		this.regexp = regexp;
		this.rememberCharacters = rememberCharacters;
	}

	TokenType(String regexp) {
		this(regexp, false);
	}


	static final TokenType[] NOEOF = {LPAREN, RPAREN, LSQUARE, RSQUARE, COMMA, WHITESPACE, ATOM, DOT};
	static {
		assert NOEOF.length == TokenType.values().length - 1;
	}

	public static final Pattern TOKENPATTERN;
	static {
		final StringBuilder tokenPattern = new StringBuilder();
		String sep = "";
		for (TokenType t : TokenType.NOEOF) {
			tokenPattern.append(String.format("%s(?<%s>%s)", sep, t.name(), t.regexp));
			sep = "|";
		}
		TOKENPATTERN = Pattern.compile(tokenPattern.toString());
	}

}

public final class PrologFactParser {
	
	static abstract class Term {
	}

	static class Functor extends Term {
		final String atom;
		final List<Term> args;
		
		public String getAtom() {
			return atom;
		}

		public List<Term> getArgs() {
			return args;
		}

		public Functor(String atom, List<Term> args) {
			this.atom = atom;
			this.args = args;
		}
		
		@Override
		public String toString() {
			if (args.isEmpty()) return atom;
			return atom + "(" + String.join(",", args.stream().map(Object::toString).collect(Collectors.toList())) + ")";
		}
	}
	
	final static class Fact extends Functor {
		public Fact(String atom, List<Term> args) {
			super(atom, args);
		}
		@Override
		public String toString() {
			return super.toString() + ".";
		}
	}
	



	final static class PrologList extends Term {
		final List<Term> elements;
		public PrologList(List<Term> elements) {
			this.elements = elements;
		}
		
		@Override
		public String toString() {
			return "[" + String.join(",", elements.stream().map(Object::toString).collect(Collectors.toList())) + "]";
		}
	}

	
	final static class Token {
		private final String symbol;
		private final TokenType tokentype;

		public String getSymbol() {
			return symbol;
		}

		public Token(TokenType tokentyp) {
			this(tokentyp, null);
		}

		public Token(TokenType tokentyp, String symbol) {
			if (tokentyp.rememberCharacters && (symbol == null)) throw new IllegalArgumentException();

			this.tokentype = tokentyp;
			this.symbol = tokentyp.rememberCharacters ? symbol : null;
		}

		public TokenType getType() {
			return tokentype;
		}

		@Override
		public String toString() {
			return "<" + tokentype + (symbol != null ? "(" + symbol + ")" : "") + ">";
		}

	}


	
	
	private Token token;
	private final Matcher tokenMatcher;
	
	
	/**
	 * Sets the input to be parsed.
	 * @param input the input to be parsed. Must be != null.
	 * @return true iff the first token differs from {@link TokenType#EOF}
	 */
	public PrologFactParser(String input) {
		if(input == null) throw new IllegalArgumentException();

		this.tokenMatcher = TokenType.TOKENPATTERN.matcher(input);
		token = null;
		nextToken();
	}

	/**
	 * Sets the current input token to the next token read from Input.
	 *
	 * @return true, iff another input token other than {@link TokenType#EOF} was read.
	 *
	 * @throws IllegalStateException iff no tokenMatcher was set (see {@link #setInput(String)}).
	 * @throws LexerError iff the input cannot be correctly tokenized (e.g., if it contains characters not corresponding to tokens).
	 */
	private boolean nextToken() {
		do {
			final int previouslyMatchedCharacterIndex = (token == null) ? 0 : tokenMatcher.end();

			if (tokenMatcher.find()) {
				// Abort if tokenMatcher had to skip characters in order to find the next valid token
				if (tokenMatcher.start() > previouslyMatchedCharacterIndex) throw new LexerError();

				// The characters matched correspond to exactly one new Token.
				// Generate this, possibly annotating it with the matched character sequence
				boolean matchingTokenFound = false;
				for (TokenType t : TokenType.NOEOF) {
					boolean tokenMatches = tokenMatcher.group(t.name()) != null;

					// The token, as defined in TokenType, are "mutually exclusive":
					assert !(matchingTokenFound && tokenMatches);

					matchingTokenFound |= tokenMatches;

					if (tokenMatches) {
						token = new Token(t, tokenMatcher.group(t.name()));
					}
				}
				assert matchingTokenFound;

			} else {
				// Abort if no more tokens could be found, but the input has not been fully read yet.
				if (previouslyMatchedCharacterIndex < tokenMatcher.regionEnd()) {
					throw new LexerError();
				}

				token = new Token(TokenType.EOF);
				return false;
			}
		} while (token.getType() == TokenType.WHITESPACE);

		return true;
	}



	public List<Token> getRemainingTokens() {
		final List<Token> tokens = new LinkedList<>();
		do {
			tokens.add(token);
		} while(nextToken());
		return tokens;
	}

	public Fact parseFact() {
		if (token.getType() == TokenType.ATOM) {
			Functor functor = (Functor) parseTerm();
			if (token.getType() != TokenType.DOT) {
				throw new ParseError();
			}
			return new Fact(functor.getAtom(), functor.getArgs());
		} else {
			throw new ParseError();
		}
	}
	
	public Term parseTerm() {
		if (token == null) { throw new IllegalStateException(); }
		
		if  (token.getType() == TokenType.ATOM) {
			final String atom = token.getSymbol();
			nextToken();
			
			switch (token.getType()) {
				case COMMA:
				case EOF:
				case RSQUARE:
				case RPAREN:
					return new Functor(atom, Collections.emptyList());
				case LPAREN:
					nextToken();
					final List<Term> arguments = parseTermList();
					if (token.getType() != TokenType.RPAREN) {
						throw new ParseError();
					}
					nextToken();
					return new Functor(atom, arguments);
				default: throw new ParseError();
			}
		} else if (token.getType() == TokenType.LSQUARE) {
			nextToken();
			if (token.getType() == TokenType.RSQUARE) {
				nextToken();
				return new PrologList(Collections.emptyList());
			}
			final List<Term> elements = parseTermList();
			if (token.getType() != TokenType.RSQUARE) {
				throw new ParseError();
			}
			nextToken();
			return new PrologList(elements);
		}
		throw new ParseError();
	}
	
	public List<Term> parseTermList() {
		List<Term> elements = new LinkedList<>();
		do {
			elements.add(parseTerm());
		} while (token.getType() == TokenType.COMMA && nextToken());
		
		switch (token.getType()) {
			case RPAREN:
			case RSQUARE:
				return elements;
			default:
				throw new ParseError();
		}
	}
}





class LexerError extends RuntimeException {
	private static final long serialVersionUID = -6554542041382870784L;
}

class ParseError extends RuntimeException {
	private static final long serialVersionUID = -2687440417554884854L;
}

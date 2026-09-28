import 'package:calc_engine/src/ast/node.dart';
import 'package:calc_engine/src/calc_result.dart';
import 'package:calc_engine/src/evaluation_exception.dart';
import 'package:calc_engine/src/lexer/lexer.dart';
import 'package:calc_engine/src/number/calc_value.dart';

/// The deepest nesting of brackets and unary signs [parse] accepts. Deeper
/// input is a syntax error, which keeps the recursion shallow.
const int maxNesting = 100;

/// Parses [tokens] into an expression tree.
///
/// Grammar, from lowest to highest precedence:
///
/// ```text
/// expression := term (('+' | '−') term)*
/// term       := unary (('×' | '÷' | implied ×) unary)*
/// unary      := ('+' | '−') unary | postfix
/// postfix    := primary '%'*
/// primary    := number | identifier | '(' expression ')'
/// ```
///
/// Multiplication is implied before `(` (`2(3)`, `(2)(3)`), and before a
/// number or name that follows `)` or `%` (`(2)3`, `10%50`). It has the same
/// precedence as `×`, so `6÷2(1+2)` is 9.
///
/// Throws an [EvaluationException]: [CalcError.incomplete] when the input
/// ends where an operand is needed (`5+`, `(2`), otherwise
/// [CalcError.syntax].
Node parse(List<Token> tokens) {
  final parser = _Parser(tokens);
  final node = parser.expression();
  if (!parser.atEnd) throw const EvaluationException(CalcError.syntax);
  return node;
}

class _Parser {
  _Parser(this._tokens);

  final List<Token> _tokens;
  int _index = 0;
  int _depth = 0;

  bool get atEnd => _index >= _tokens.length;

  TokenKind? get _peek => atEnd ? null : _tokens[_index].kind;

  TokenKind? get _previous => _index == 0 ? null : _tokens[_index - 1].kind;

  Token _advance() => _tokens[_index++];

  /// Parses [parseInner] one nesting level deeper.
  Node _nested(Node Function() parseInner) {
    if (++_depth > maxNesting) {
      throw const EvaluationException(CalcError.syntax);
    }
    final node = parseInner();
    _depth--;
    return node;
  }

  Node expression() {
    var node = _term();
    while (_peek == TokenKind.plus || _peek == TokenKind.minus) {
      final operator = _advance().kind == TokenKind.plus
          ? BinaryOperator.add
          : BinaryOperator.subtract;
      node = BinaryNode(operator, node, _term());
    }
    return node;
  }

  Node _term() {
    var node = _unary();
    while (true) {
      if (_peek == TokenKind.times || _peek == TokenKind.divide) {
        final operator = _advance().kind == TokenKind.times
            ? BinaryOperator.multiply
            : BinaryOperator.divide;
        node = BinaryNode(operator, node, _unary());
      } else if (_impliesMultiplication) {
        node = BinaryNode(BinaryOperator.multiply, node, _unary());
      } else {
        return node;
      }
    }
  }

  /// Whether the next token starts an operand that multiplies the one just
  /// parsed without a written `×`.
  bool get _impliesMultiplication {
    final next = _peek;
    if (next == TokenKind.openBracket) return true;
    final operandEnd =
        _previous == TokenKind.closeBracket || _previous == TokenKind.percent;
    return operandEnd &&
        (next == TokenKind.number || next == TokenKind.identifier);
  }

  Node _unary() {
    if (_peek == TokenKind.minus || _peek == TokenKind.plus) {
      final negate = _advance().kind == TokenKind.minus;
      final operand = _nested(_unary);
      return negate ? NegateNode(operand) : operand;
    }
    return _postfix();
  }

  Node _postfix() {
    var node = _primary();
    while (_peek == TokenKind.percent) {
      _advance();
      node = PercentNode(node);
    }
    return node;
  }

  Node _primary() {
    if (atEnd) throw const EvaluationException(CalcError.incomplete);
    final token = _advance();
    switch (token.kind) {
      case TokenKind.number:
        return NumberNode(CalcValue.parse(token.text));
      case TokenKind.identifier:
        return VariableNode(token.text);
      case TokenKind.openBracket:
        if (_peek == TokenKind.closeBracket) {
          throw const EvaluationException(CalcError.syntax);
        }
        final inner = _nested(expression);
        if (atEnd) throw const EvaluationException(CalcError.incomplete);
        if (_advance().kind != TokenKind.closeBracket) {
          throw const EvaluationException(CalcError.syntax);
        }
        return inner;
      case TokenKind.plus ||
          TokenKind.minus ||
          TokenKind.times ||
          TokenKind.divide ||
          TokenKind.percent ||
          TokenKind.closeBracket:
        throw const EvaluationException(CalcError.syntax);
    }
  }
}

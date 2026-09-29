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
/// unary      := ('+' | '−') unary | power
/// power      := postfix ('^' unary)?
/// postfix    := primary ('%' | '!')*
/// primary    := number | constant | function '(' expression ')'
///             | identifier | '(' expression ')'
/// ```
///
/// Multiplication is implied before `(` (`2(3)`, `(2)(3)`), before a number
/// or name that follows `)`, `%` or `!` (`(2)3`, `10%50`), and before a name
/// that follows a number (`2π`, `5sin(30)` — but not `2 3`, two numbers in a
/// row, which stays a syntax error). It has the same precedence as `×`, so
/// `6÷2(1+2)` is 9.
///
/// `^` is right-associative and binds tighter than unary minus but looser
/// than `%`/`!`: `−3^2` is `−9`, and `2^3^2` is `2^(3^2)` = 512. Its right
/// side parses as `unary`, so `2^−3` also works.
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
    // A number directly followed by a name (`2π`, `5sin(30)`) implies ×, but
    // two numbers in a row (`1 2`) do not: that's whitespace-separated junk,
    // not an operand boundary.
    if (_previous == TokenKind.number) return next == TokenKind.identifier;
    final operandEnd =
        _previous == TokenKind.closeBracket ||
        _previous == TokenKind.percent ||
        _previous == TokenKind.factorial;
    return operandEnd &&
        (next == TokenKind.number || next == TokenKind.identifier);
  }

  Node _unary() {
    if (_peek == TokenKind.minus || _peek == TokenKind.plus) {
      final negate = _advance().kind == TokenKind.minus;
      final operand = _nested(_unary);
      return negate ? NegateNode(operand) : operand;
    }
    return _power();
  }

  /// `^` is right-associative: its right side is a full `unary`, so a
  /// second `^` (or a leading `-`) on the right recurses back here.
  Node _power() {
    final node = _postfix();
    if (_peek != TokenKind.caret) return node;
    _advance();
    return BinaryNode(BinaryOperator.power, node, _nested(_unary));
  }

  Node _postfix() {
    var node = _primary();
    while (true) {
      switch (_peek) {
        case TokenKind.percent:
          _advance();
          node = PercentNode(node);
        case TokenKind.factorial:
          _advance();
          node = FactorialNode(node);
        case _:
          return node;
      }
    }
  }

  Node _primary() {
    if (atEnd) throw const EvaluationException(CalcError.incomplete);
    final token = _advance();
    switch (token.kind) {
      case TokenKind.number:
        return NumberNode(CalcValue.parse(token.text));
      case TokenKind.identifier:
        return _identifierNode(token.text);
      case TokenKind.openBracket:
        return _parenthesized();
      case TokenKind.plus ||
          TokenKind.minus ||
          TokenKind.times ||
          TokenKind.divide ||
          TokenKind.percent ||
          TokenKind.factorial ||
          TokenKind.caret ||
          TokenKind.closeBracket:
        throw const EvaluationException(CalcError.syntax);
    }
  }

  Node _identifierNode(String name) {
    switch (name) {
      case 'π':
        return const ConstantNode(CalcConstant.pi);
      case 'e':
        return const ConstantNode(CalcConstant.e);
      default:
        final function = _functions[name];
        if (function == null) return VariableNode(name);
        if (_peek != TokenKind.openBracket) {
          throw const EvaluationException(CalcError.syntax);
        }
        _advance();
        return FunctionCallNode(function, _nested(_bracketedExpression));
    }
  }

  /// The opening bracket (of a group, or a function call) was already
  /// consumed; parses its contents and consumes the matching `)`.
  Node _bracketedExpression() {
    if (_peek == TokenKind.closeBracket) {
      throw const EvaluationException(CalcError.syntax);
    }
    final inner = expression();
    if (atEnd) throw const EvaluationException(CalcError.incomplete);
    if (_advance().kind != TokenKind.closeBracket) {
      throw const EvaluationException(CalcError.syntax);
    }
    return inner;
  }

  Node _parenthesized() => _nested(_bracketedExpression);
}

const Map<String, CalcFunction> _functions = {
  'sin': CalcFunction.sin,
  'cos': CalcFunction.cos,
  'tan': CalcFunction.tan,
  'asin': CalcFunction.asin,
  'acos': CalcFunction.acos,
  'atan': CalcFunction.atan,
  'sinh': CalcFunction.sinh,
  'cosh': CalcFunction.cosh,
  'tanh': CalcFunction.tanh,
  'log': CalcFunction.log,
  'ln': CalcFunction.ln,
  'sqrt': CalcFunction.sqrt,
  'cbrt': CalcFunction.cbrt,
  'abs': CalcFunction.abs,
};

class PassSessionQuestion {
  final int id;
  final int? selectedStars;
  final String? shortAnswer;
  final List<PassSessionQuestionAnswer>? sessionQuestionAnswers;

  PassSessionQuestion({
    required this.id,
    this.selectedStars,
    this.shortAnswer,
    this.sessionQuestionAnswers,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {'Id': id};

    if (selectedStars != null) data['SelectedStars'] = selectedStars;
    if (shortAnswer != null) data['ShortAnswer'] = shortAnswer;

    // Если массив ответов есть - шлем его. Если это текстовый вопрос без вариантов - не шлем пустой [], чтобы EF не ругался.
    if (sessionQuestionAnswers != null && sessionQuestionAnswers!.isNotEmpty) {
      data['SessionQuestionAnswers'] = sessionQuestionAnswers!
          .map((v) => v.toJson())
          .toList();
    }

    return data;
  }
}

class PassSessionQuestionAnswer {
  final int id;
  final bool selected;
  final int? order;

  PassSessionQuestionAnswer({
    required this.id,
    required this.selected,
    this.order,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {'Id': id, 'Selected': selected};
    if (order != null) data['Order'] = order;
    return data;
  }
}

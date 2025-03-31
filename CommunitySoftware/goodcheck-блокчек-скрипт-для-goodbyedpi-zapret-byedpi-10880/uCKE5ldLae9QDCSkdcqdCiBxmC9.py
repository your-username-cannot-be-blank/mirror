import itertools

# Возможные значения для каждой функции
values = {
    "ttl": [1, 2, 3, 4, 5, 6],
    "pos": [1, 2, 3, 5, 10, 50],  # Используем для split-pos
    "repeats": list(range(1, 11)),
    "fooling": ["badsum", "badseq", "datanoack", "md5sig"],
    "tls": ["0x00000000"],  # Строгое значение для tls
    "seqovl": [1, 2, 3]
}

# Основы и их комбинации + поддерживаемые функции
bases = {
    "split": ["ttl", "pos", "repeats", "fooling"],
    "split2": ["pos", "repeats", "seqovl"],
    "fake": ["ttl", "repeats", "fooling", "tls"],
    "disorder": ["ttl", "repeats", "fooling"],
    "disorder2": ["repeats", "seqovl"],
    "syndata": ["repeats", "fooling"],
    # Комбинации основ
    "fake,disorder": ["ttl", "repeats", "fooling", "tls"],
    "fake,disorder2": ["repeats", "seqovl", "tls"],
    "fake,split": ["ttl", "pos", "repeats", "fooling", "tls"],
    "fake,split2": ["pos", "repeats", "seqovl", "tls", "fooling"],
    "syndata,disorder2": ["repeats", "seqovl"],
    "syndata,split2": ["pos", "repeats", "seqovl"]
}

def choose_options(options):
    """Позволяет пользователю выбрать несколько функций для включения в стратегию."""
    chosen = []
    print("Выберите функции для включения (введите номера через пробел):")
    for i, option in enumerate(options, 1):
        print(f"{i}. {option}")

    choices = input("Ваш выбор: ").split()
    for choice in choices:
        index = int(choice) - 1
        if 0 <= index < len(options):
            chosen.append(options[index])

    return chosen

def generate_combinations(base, selected_options):
    """Генерация всех комбинаций на основе выбранных опций."""
    strategies = []

    # Создаём словарь только с выбранными опциями
    params = {option: values[option] for option in selected_options}

    # Генерируем все возможные комбинации
    for combination in itertools.product(*params.values()):
        strategy = f"--dpi-desync={base}"
        for option, value in zip(selected_options, combination):
            if option == "tls":
                strategy += f" --dpi-desync-fake-tls={value}"  # Используем строковое значение для tls
            elif option == "pos":
                strategy += f" --dpi-desync-split-pos={value}"  # Исправляем на split-pos
            else:
                strategy += f" --dpi-desync-{option}={value}"
        strategies.append(strategy)

    return strategies

def main():
    print("Выберите основу для генерации стратегий:")
    for i, base in enumerate(bases.keys(), 1):
        print(f"{i}. {base}")

    base_choice = int(input("Введите номер выбранной основы: ")) - 1
    if base_choice < 0 or base_choice >= len(bases):
        print("Неверный выбор!")
        return

    base = list(bases.keys())[base_choice]
    available_options = bases[base]

    # Пользователь выбирает функции для включения в стратегию
    selected_options = choose_options(available_options)

    # Генерируем стратегии
    strategies = generate_combinations(base, selected_options)

    # Сохраняем стратегии в файл
    filename = f"{base}_strategies_custom.txt"
    with open(filename, "w") as f:
        f.write("/First 2 uncommented lines are reserved, DO NOT REMOVE\n/\n")
        for strategy in strategies:
            f.write(strategy + "\n")

    print(f"Генерация завершена! Стратегии сохранены в {filename}")

if __name__ == "__main__":
    main()

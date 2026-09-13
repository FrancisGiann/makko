with open('mobile/test/home_widget_test.dart', 'r') as f:
    content = f.read()

content = content.replace("Uri.parse('makko://capture')", "Uri.parse('makko://makko/capture')")

with open('mobile/test/home_widget_test.dart', 'w') as f:
    f.write(content)

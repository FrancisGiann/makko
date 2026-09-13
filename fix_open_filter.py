with open('mobile/lib/services/issue_service.dart', 'r') as f:
    content = f.read()

target_validation = """    if (!const [
          'all',
          'todo',
          'in_progress',
          'done',
        ].contains(filters.status) ||"""
        
replacement_validation = """    if (!const [
          'all',
          'open',
          'todo',
          'in_progress',
          'done',
        ].contains(filters.status) ||"""

content = content.replace(target_validation, replacement_validation)

target_query = """    if (filters.status != 'all') {
      query = query.eq('status', filters.status);
    }"""
    
replacement_query = """    if (filters.status != 'all') {
      if (filters.status == 'open') {
        query = query.neq('status', 'done');
      } else {
        query = query.eq('status', filters.status);
      }
    }"""
    
content = content.replace(target_query, replacement_query)

target_count = """    if (filters.status != 'all')
      countQuery = countQuery.eq('status', filters.status);"""
      
replacement_count = """    if (filters.status != 'all') {
      if (filters.status == 'open') {
        countQuery = countQuery.neq('status', 'done');
      } else {
        countQuery = countQuery.eq('status', filters.status);
      }
    }"""
    
content = content.replace(target_count, replacement_count)

with open('mobile/lib/services/issue_service.dart', 'w') as f:
    f.write(content)
print("Updated issue_service to support 'open'")


def lambda_handler(event, context):
    return f"Uma coisa é certa: {event.get('body', '')}"

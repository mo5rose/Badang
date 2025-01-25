def handle_error(error, context=None):
    """
    Log and handle errors gracefully.
    """
    error_message = f"Error: {error}"
    if context:
        error_message += f" | Context: {context}"
    print(error_message)
    return {"error": error_message}
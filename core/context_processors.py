def chat_globals(request):
    first_name = ""
    if request.user.is_authenticated:
        first_name = request.user.first_name or request.user.email.split("@")[0]
    return {
        "rag_endpoint": "/chat-proxy/",
        "user_first_name": first_name,
    }

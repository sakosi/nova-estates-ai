const chatMessages = document.getElementById("chat-messages");
const chatForm = document.getElementById("chat-form");
const messageInput = document.getElementById("message-input");
const sendButton = document.getElementById("send-button");
const resetButton = document.getElementById("reset-chat");
const quickButtons = document.querySelectorAll("[data-prompt]");

let isProcessing = false;

const welcomeMessage =
    "Welcome to Nova Estates! I'm Nova, your personal AI property advisor.\n\n" +
    "Tell me about your preferred location, budget and property type, " +
    "or ask me about our services.";


// Display messages safely
// Safe inline Markdown formatting
function formatInline(container, text) {
    const parts = text.split(/(\*\*[^*\n]+\*\*)/g);

    for (const part of parts) {
        if (part.startsWith("**") && part.endsWith("**")) {
            const strong = document.createElement("strong");
            strong.textContent = part.slice(2, -2);
            container.appendChild(strong);
        } else {
            container.appendChild(document.createTextNode(part));
        }
    }
}


// Safe Markdown rendering
function renderMarkdown(container, text) {
    const lines = text.split(/\r?\n/);
    let currentList = null;

    for (const rawLine of lines) {
        const line = rawLine.trim();

        if (!line) {
            currentList = null;
            continue;
        }

        const heading = line.match(/^#{1,6}\s+(.+)$/);
        const bullet = line.match(/^[-*+]\s+(.+)$/);
        const numbered = line.match(/^\d+\.\s+(.+)$/);

        if (heading) {
            currentList = null;

            const title = document.createElement("h4");
            formatInline(title, heading[1]);
            container.appendChild(title);

        } else if (bullet || numbered) {

            const listType = numbered ? "OL" : "UL";

            if (!currentList || currentList.tagName !== listType) {
                currentList = document.createElement(listType);
                container.appendChild(currentList);
            }

            const item = document.createElement("li");
            formatInline(item, (bullet || numbered)[1]);
            currentList.appendChild(item);

        } else {
            currentList = null;

            const paragraph = document.createElement("p");
            formatInline(paragraph, line);
            container.appendChild(paragraph);
        }
    }
}


// Display messages safely
function addMessage(text, role) {
    const message = document.createElement("div");

    message.classList.add("message", role);

    if (role === "assistant") {
        renderMarkdown(message, text);
    } else {
        message.textContent = text;
    }

    chatMessages.appendChild(message);
    chatMessages.scrollTop = chatMessages.scrollHeight;

    return message;
}

// Prevent simultaneous requests
function setProcessing(value) {
    isProcessing = value;

    sendButton.disabled = value;
    messageInput.disabled = value;
    resetButton.disabled = value;

    quickButtons.forEach(button => {
        button.disabled = value;
    });

    chatMessages.setAttribute("aria-busy", String(value));
}


// Send message to FastAPI
async function sendMessage(text) {
    const message = text.trim();

    if (!message || isProcessing) {
        return;
    }

    if (message.length > 2000) {
        addMessage("Your message is too long.", "error");
        return;
    }

    setProcessing(true);

    addMessage(message, "user");
    messageInput.value = "";

    const loading = addMessage(
        "Nova is thinking...",
        "assistant"
    );

    loading.classList.add("loading");

    try {
        const response = await fetch("/api/chat", {
            method: "POST",
            credentials: "same-origin",

            headers: {
                "Content-Type": "application/json"
            },

            body: JSON.stringify({
                message: message
            })
        });

        if (!response.ok) {
            throw new Error("AI service unavailable");
        }

        const data = await response.json();

        if (typeof data.response !== "string" ||
            !data.response.trim()) {
            throw new Error("Invalid response");
        }

        loading.remove();

        addMessage(data.response, "assistant");

    } catch (error) {

        loading.remove();

        addMessage(
            "Nova is temporarily unavailable. Please try again.",
            "error"
        );

    } finally {

        setProcessing(false);
        messageInput.focus();

    }
}


// Handle chat form
chatForm.addEventListener("submit", event => {
    event.preventDefault();

    sendMessage(messageInput.value);
});


// Quick prompts
quickButtons.forEach(button => {
    button.addEventListener("click", () => {
        sendMessage(button.dataset.prompt);
    });
});


// Reset conversation
resetButton.addEventListener("click", async () => {

    if (isProcessing) {
        return;
    }

    setProcessing(true);

    try {
        const response = await fetch("/api/chat/reset", {
            method: "POST",
            credentials: "same-origin"
        });

        if (!response.ok) {
            throw new Error("Reset failed");
        }

        chatMessages.replaceChildren();

        addMessage(welcomeMessage, "assistant");

    } catch (error) {

        addMessage(
            "Unable to start a new conversation. Please try again.",
            "error"
        );

    } finally {

        setProcessing(false);
        messageInput.focus();

    }
});


// Initial welcome message
addMessage(welcomeMessage, "assistant");
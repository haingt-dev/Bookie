# NotebookLM Deep Queries

Query the research hub for structured insights. These queries benefit from ALL sources — not just the book text.

First, detect the book configuration and run the matching query set.

## Base queries (always run)

- "What are the 5 most important concepts? For each, give the concept, a compelling story/example, and practical application."
- "What are the most quotable lines? Include exact quotes with context."
- "What stories or examples are most dramatic and visually interesting? Describe in detail."
- "What are the main criticisms or limitations? Use evidence from all sources."
- "What do Vietnamese readers and reviewers say? What resonates most with Vietnamese audiences?"
- "How has this been adapted (anime, film, etc.)? How do adaptations differ from the original?"

## Twin/multi-book same author — add these queries

- "Compare [Book A] vs [Book B] in detail: character journeys, themes, tone, structure. What's symmetric? What's opposite?"
- "How did the author's thinking evolve between the books? What changed in their worldview, and why?"
- "What does reading both books together reveal that reading either one alone doesn't?"

## Multi-book different authors — add these queries

- "Where do these authors fundamentally agree? Where do they contradict each other?"
- "What does NONE of these books address? What's the blind spot they all share?"
- "If these authors debated each other, what would the core disagreement be?"

## Fallback

If any MCP tool fails, fall back: tell Hai to use NotebookLM web UI (notebooklm.google.com) and paste results manually.

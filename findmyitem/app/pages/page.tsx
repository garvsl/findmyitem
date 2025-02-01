'use client';

import { useState } from "react";

export default function Home() {
  const [input, setInput] = useState("");
  const [response, setResponse] = useState("");
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (!input.trim()) {
      setResponse("Please enter a prompt.");
      return;
    }

    setLoading(true);
    setResponse("Loading...");

    try {
      const res = await fetch("/api/gemini", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ prompt: input }),
      });

      if (!res.ok) {
        throw new Error(`Error: ${res.status} ${res.statusText}`);
      }

      const data = await res.json();
      //console.log(data);
      setResponse(data.result || "No response received.");
    } catch (error) {
      console.error("Error fetching data:", error);
      setResponse("An error occurred. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ textAlign: "center", marginTop: "50px" }}>
      <h1>Gemini AI with Next.js</h1>
      <form onSubmit={handleSubmit}>
        <input
          type="text"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder="Ask Gemini AI..."
          style={{ padding: "10px", width: "300px", color: "black" }}
        />
        <button 
          type="submit" 
          style={{ marginLeft: "10px", padding: "10px" }}
          disabled={loading}
        >
          {loading ? "Loading..." : "Submit"}
        </button>
      </form>
      <p style={{ marginTop: "20px", color: loading ? "gray" : "black" }}>
        {response}
      </p>
    </div>
  );
}

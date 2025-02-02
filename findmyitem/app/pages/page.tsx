'use client';

import { useState } from "react";

export default function Home() {
  const [input, setInput] = useState("");
  const [response, setResponse] = useState("");
  const [loading, setLoading] = useState(false);
  const [data, setData] = useState([]);
  const handleSubmit = async (e) => {
    e.preventDefault();

    if (!input.trim()) {
      setResponse("Please enter a prompt.");
      return;
    }

    setLoading(true);
    setResponse("Loading...");
    const JsonData = [
      {
        "item": "Banana",
        "category": "Fruit",
        "average_weight": "120 grams",
        "carbon_footprint_unit": "kg CO2e"
      },
      {
        "item": "Apple",
        "category": "Fruit",
        "average_weight": "180 grams",
        "carbon_footprint_unit": "kg CO2e"
      },
      {
        "item": "Orange",
        "category": "Fruit",
        "average_weight": "130 grams",
        "carbon_footprint_unit": "kg CO2e"
      },
      {
        "item": "Strawberry",
        "category": "Fruit",
        "average_weight": "12 grams",
        "carbon_footprint_unit": "kg CO2e"
      },
      {
        "item": "Grape",
        "category": "Fruit",
        "average_weight": "5 grams",
        "carbon_footprint_unit": "kg CO2e"
      }
    ]
    setData(JsonData);
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
    function findItem(item){
      
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

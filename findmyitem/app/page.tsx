"use client";

import React, { useEffect, useState } from "react";
import {
  PieChart,
  Pie,
  Cell,
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from "recharts";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Button } from "@/components/ui/button";

const COLORS = [
  "#0088FE",
  "#00C49F",
  "#FFBB28",
  "#FF8042",
  "#A28DFF",
  "#FF5678",
  "#34D399",
  "#F97316",
  "#E63946",
  "#457B9D",
  "#2A9D8F",
  "#D4A373",
  "#F4A261",
  "#8D99AE",
  "#264653",
  "#E76F51",
  "#6A0572",
  "#D00000",
  "#FF9F1C",
  "#4A90E2",
];

export default function CarbonFootPrint() {
  const [item, setItem] = useState<any>("");
  const [results, setResults] = useState<any>();
  const [loading, setLoading] = useState<any>(false);
  const [error, setError] = useState<any>(null);
  const [cart, setCart] = useState<any>([]);
  const [highest, setHighest] = useState<any>(0);
  const [highestName, setHighestName] = useState<any>("");

  useEffect(() => {
    async function getDBdata() {
      try {
        const response = await fetch(
          "https://server-1sqv.onrender.com/history"
        );
        if (!response.ok) {
          throw new Error("Failed to fetch data");
        }
        const data = await response.json();
        console.log("dat", data);

        const today = new Date().toISOString().split("T")[0];
        const todaysData = data.filter((entry: any) => entry.date === today);

        setResults(data);
        setCart(todaysData);
      } catch (error) {
        console.error("Error fetching data:", error);
      }
    }

    getDBdata();
  }, []);

  const handleSubmit = async (e: any) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const res = await fetch(
        `https://server-1sqv.onrender.com/carbon?item=${item}`
      );
      if (!res.ok) {
        throw new Error(`Error: ${res.statusText}`);
      }
      const data = await res.json();
      console.log(data);

      setResults((prevResults: any) => [...prevResults, data]);

      const today = new Date().toISOString().split("T")[0];
      if (data.date === today) {
        setCart((prevCart: any) => [...prevCart, data]);
      }

      if (data.carbon_footprint > highest) {
        setHighest(data.carbon_footprint);
        setHighestName(data.product);
      }
    } catch (error: any) {
      setError(error.message);
    } finally {
      setLoading(false);
    }
  };

  let pieData;
  if (results) {
    pieData = results.map((result: any) => ({
      name: result.product,
      value: result.carbon_footprint,
    }));
  }

  return (
    <div style={{ textAlign: "center", marginTop: "50px" }}>
      <Button className="bg-blue-500 text-white hover:bg-blue-700 px-4 py-2 rounded">
        Carbon Footprint Calculator
      </Button>
      <form onSubmit={handleSubmit}>
        <input
          type="text"
          value={item}
          onChange={(e) => setItem(e.target.value)}
          placeholder="Enter item name"
          style={{ padding: "10px", width: "300px", borderRadius: "5px" }}
        />
        <button
          type="submit"
          className="bg-blue-500"
          style={{
            marginLeft: "10px",
            padding: "10px",
            color: "white",
            borderRadius: "5px",
          }}
        >
          Submit
        </button>
      </form>
      {loading && <p>Loading...</p>}
      {error && <p style={{ color: "blue" }}>{error}</p>}

      <div style={{ marginTop: "20px" }}>
        <h2>Results</h2>
        <div style={{ display: "flex", flexDirection: "column", gap: "10px" }}>
          {cart.length > 0 &&
            cart.map((entry: any, index: any) => (
              <div
                key={index}
                style={{
                  display: "flex",
                  gap: "10px",
                  justifyContent: "center",
                  flexWrap: "wrap",
                }}
              >
                <div
                  style={{
                    border: "1px solid #ddd",
                    borderRadius: "8px",
                    padding: "20px",
                    maxWidth: "400px",
                    boxShadow: "0 4px 8px rgba(0, 0, 0, 0.1)",
                    backgroundColor: "#f9f9f9",
                  }}
                >
                  <p>
                    <strong>Product:</strong> {entry.product}
                  </p>
                  <p>
                    <strong>Unit of Product:</strong> {entry.unit_of_product}
                  </p>
                  <p>
                    <strong>Number of Units:</strong> {entry.number_of_units}
                  </p>
                </div>

                <div
                  style={{
                    border: "1px solid #ddd",
                    borderRadius: "8px",
                    padding: "20px",
                    maxWidth: "400px",
                    boxShadow: "0 4px 8px rgba(0, 0, 0, 0.1)",
                    backgroundColor: "#f9f9f9",
                  }}
                >
                  <p>
                    <strong>Carbon Footprint:</strong>{" "}
                    {entry.carbon_footprint + entry.unit_of_carbon}
                  </p>
                  <p>
                    <strong>Sustainable Brand:</strong>{" "}
                    {entry.sustainable_brand}
                  </p>
                  <p>
                    <strong>Date:</strong> {entry.date}
                  </p>
                </div>
              </div>
            ))}
        </div>

        {results && results.length > 0 && (
          <ResponsiveContainer width="100%" height={350}>
            <PieChart>
              <Tooltip />
              <Pie
                data={pieData}
                dataKey="value"
                nameKey="name"
                cx="50%"
                cy="50%"
                outerRadius={150}
                fill="#8884d8"
                label
              >
                {pieData.map((entry: any, index: number) => (
                  <Cell
                    key={`cell-${index}`}
                    fill={COLORS[index % COLORS.length]}
                  />
                ))}
              </Pie>
            </PieChart>
          </ResponsiveContainer>
        )}

        {results && results.length > 0 && (
          <ResponsiveContainer width="100%" height={350}>
            <AreaChart
              data={results}
              margin={{ top: 20, right: 30, left: 20, bottom: 5 }}
            >
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="product" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Area
                type="monotone"
                dataKey="carbon_footprint"
                stroke="#090374"
                fill="#1d62d2"
              />
            </AreaChart>
          </ResponsiveContainer>
        )}

        {results && results.length > 0 && (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Product</TableHead>
                <TableHead>Unit of Product</TableHead>
                <TableHead>Number of Units</TableHead>
                <TableHead>Carbon Footprint</TableHead>
                <TableHead>Unit of Carbon</TableHead>
                <TableHead>Date</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {results.map((result: any, index: any) => (
                <TableRow key={index}>
                  <TableCell>{result.product}</TableCell>
                  <TableCell>{result.unit_of_product}</TableCell>
                  <TableCell>{result.number_of_units}</TableCell>
                  <TableCell>{result.carbon_footprint}</TableCell>
                  <TableCell>{result.unit_of_carbon}</TableCell>
                  <TableCell>{result.date}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </div>
    </div>
  );
}

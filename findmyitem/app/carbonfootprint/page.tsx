'use client';

import React, { useEffect, useState } from 'react';
import { Label, PieChart, Pie, Cell, AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Button } from '@/components/ui/button';
import { TableColumnsSplit, TrendingUp } from 'lucide-react';
import database from "../api/carbon/route"

const COLORS = [
    '#0088FE', '#00C49F', '#FFBB28', '#FF8042', // Original colors
    '#A28DFF', '#FF5678', '#34D399', '#F97316',
    '#E63946', '#457B9D', '#2A9D8F', '#D4A373',
    '#F4A261', '#8D99AE', '#264653', '#E76F51',
    '#6A0572', '#D00000', '#FF9F1C', '#4A90E2'
  ];
  
export default function CarbonFootPrint() {

  const [item, setItem] = useState('');
  const [results, setResults] = useState(database);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [cart, setCart] = useState("");
  const [highest, setHighest] = useState(0);
  const [highestName, setHighestName] = useState("");

  useEffect(() => {
    async function getDBdata() {
      try {
        const response = await fetch("http://localhost:3000/api/history");
        if (!response.ok) {
          throw new Error("Failed to fetch data");
        }
        const data = await response.json();
        setResults(data);
      } catch (error) {
        console.error("Error fetching data:", error);
      }
    }

    getDBdata();
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const res = await fetch(`/api/carbon?item=${item}`);
      if (!res.ok) {
        throw new Error(`Error: ${res.statusText}`);
      }
      const data = await res.json();
      
      //console.log(testData);
      setResults((prevResults) => [...prevResults, data]);
      setCart(data);
        if (data.carbon_footprint > highest) {
            setHighest(data.carbon_footprint);
            setHighestName(data.product);
        }
    } catch (error) {
      setError(error.message);
    } finally {
      setLoading(false);
    }
  };

  const map = (data) => {
    return data.map(result => ({
      product: result.product,
      unit_of_product: result.unit_of_product,
      number_of_units: result.number_of_units,
      carbon_footprint: result.carbon_footprint,
      unit_of_carbon: result.unit_of_carbon,
      date: result.date,
    }));
  };
  const pieData = results.map(result => ({  
    name: result.product,
    value: result.carbon_footprint
  }));

 

  return (
    <div style={{ textAlign: 'center', marginTop: '50px' }}>
      <Button className = "bg-blue-500 text-white hover:bg-blue-700 px-4 py-2 rounded" style={{ textAlign: 'right', marginTop: '50px' }}>Carbon Footprint Calculator</Button>
      <form onSubmit={handleSubmit}>
        <input
          type="text"
          value={item}
          onChange={(e) => setItem(e.target.value)}
          placeholder="Enter item name"
          style={{ padding: '10px', width: '300px', borderRadius: '5px' }}
        />
        <button type="submit" className = "bg-blue-500" style={{ marginLeft: '10px', padding: '10px', color: 'white', borderRadius: '5px' }}>
          Submit
        </button>

      </form>
      {loading && <p>Loading...</p>}
      {error && <p style={{ color: 'blue' }}>{error}</p>}
      <div style={{ marginTop: '20px' }}>
        <h2>Results</h2>
      <div style={{ display: 'flex', justifyContent: 'space-around', gap: '20px', flexWrap: 'wrap' }}>
      
      {highest > 0 && (
          <div style={{
            border: '1px solid #ddd',
            borderRadius: '8px',
            padding: '20px',
            maxWidth: '400px',
            margin: '20px auto',
            boxShadow: '0 4px 8px rgba(0, 0, 0, 0.1)',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            backgroundColor: '#f9f9f9'
          }}>
            <div style={{ display: 'flex', alignItems: 'center' }}>
              <TrendingUp size={24} color="#FF8042" style={{ marginRight: '10px' }} />
              <div>
                <p style={{ margin: 0, fontWeight: 'bold' }}>Highest Carbon Footprint</p>
                <p style={{ margin: 0 }}>{highest} kgCO2e </p>
              </div>
            </div>
            <div style={{ display: 'flex', alignItems: 'center' }}>
              <TrendingUp size={24} color="#FF8042" style={{ marginRight: '10px' }} />
              <div>
                <p style={{ margin: 0, fontWeight: 'bold' }}>Product</p>
                <p style={{ margin: 0 }}>{highestName}</p>
              </div>
            </div>
          </div>
        )}
      {cart && (
          <div style={{
            border: '1px solid #ddd',
            borderRadius: '8px',
            padding: '20px',
            maxWidth: '400px',
            margin: '20px auto',
            boxShadow: '0 4px 8px rgba(0, 0, 0, 0.1)',
            display: 'flex',
            justifyContent: 'space-between',
            gap: '20px',
          }}>
            <div>
              <p><strong>Product:</strong> {cart.product}</p>
              <p><strong>Unit of Product:</strong> {cart.unit_of_product}</p>
              <p><strong>Number of Units:</strong> {cart.number_of_units}</p>
            </div>
            
            <div>
              <p><strong>Carbon Footprint:</strong> {cart.carbon_footprint}</p>
              <p><strong>Unit of Carbon:</strong> {cart.unit_of_carbon}</p>
              <p><strong>Date:</strong> {cart.date}</p>
            </div>
          </div>
        )}
        {results.length > 0 && (
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
                {pieData.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                ))}
              </Pie>
            </PieChart>
          </ResponsiveContainer>
        )}
        </div>
      

        {results.length > 0 && (
          <ResponsiveContainer width="100%" height={350}>
            <AreaChart
              data={map(results)}
              margin={{
                top: 20, right: 30, left: 20, bottom: 5,
              }}
            >
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="product" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Area type="monotone" dataKey="carbon_footprint" stroke="#090374" fill="#1d62d2" />
            </AreaChart>
          </ResponsiveContainer>
        )}

        

{results.length > 0 && (
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
      {results.map((result, index) => (
          
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
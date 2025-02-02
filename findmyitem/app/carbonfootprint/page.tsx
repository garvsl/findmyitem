'use client';

import React, { useState } from 'react';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
//import 'button'
import { Button } from '@/components/ui/button';
export default function CarbonFootPrint() {
  const [item, setItem] = useState('');
  const [results, setResults] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

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
      setResults((prevResults) => [...prevResults, data]);
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

  return (
    <div style={{ textAlign: 'center', marginTop: '50px' }}>
      <Button>Carbon Footprint Calculator</Button>
      <form onSubmit={handleSubmit}>
        <input
          type="text"
          value={item}
          onChange={(e) => setItem(e.target.value)}
          placeholder="Enter item name"
          style={{ padding: '10px', width: '300px', rounded : '5px' }}
        />
        <button type="submit" style={{ marginLeft: '10px', padding: '10px' }}>
          Submit
        </button>
      </form>
      {loading && <p>Loading...</p>}
      {error && <p style={{ color: 'blue' }}>{error}</p>}
      <div style={{ marginTop: '20px' }}>
        <h2>Results</h2>

        {results.length > 0 && (
          <ResponsiveContainer width="100%" height={400}>
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
              <Area type="monotone" dataKey="carbon_footprint" stroke="#8884d8" fill="#8884d8" />
            </AreaChart>
          </ResponsiveContainer>
        )}
      </div>
    </div>
  );
}
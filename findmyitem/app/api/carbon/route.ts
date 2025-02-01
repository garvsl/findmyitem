import { GoogleGenerativeAI } from "@google/generative-ai";
import { NextResponse } from "next/server";
import { type NextRequest } from 'next/server'
import dotenv from 'dotenv';
dotenv.config();

export async function GET(
  req: NextRequest
) {
  const item = req.nextUrl.searchParams.get("item") as string
  const apiKey = process.env.GEMINI_KEY
  console.log(apiKey)
  const genAI = new GoogleGenerativeAI(String(apiKey));


  const model = genAI.getGenerativeModel({
      model: "gemini-1.5-flash",
      generationConfig: {"responseMimeType": "application/json"},
    });
    
  const prompt = `get the carbon footprint of ${item} from farm to grocery store and give it using this JSON schema:

  CarbonFootPrint = {
    "product": str,
    "unit_of_product": str,
    "number_of_units": str,
    "carbon_footprint": number, 
    "unit_of_carbon" : str
  }

  Return: CarbonFootPrint`;

  const data = await model.generateContent(prompt)
  const result = await data.response.text()
  console.log(result)
  const jsonObject = JSON.parse(result);
  console.log(jsonObject)
 
  return NextResponse.json(jsonObject)
}
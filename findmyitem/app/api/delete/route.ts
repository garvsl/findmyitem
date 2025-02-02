import { NextResponse } from "next/server";
import { type NextRequest } from 'next/server'
import dotenv from 'dotenv';
dotenv.config();
import database from '../carbon/route'

export async function GET(
    req: NextRequest
  ) {
    database.pop()
  return NextResponse.json(database)
}
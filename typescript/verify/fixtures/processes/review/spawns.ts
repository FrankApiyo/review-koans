import { execSync } from "node:child_process"
import { WRITE, marker } from "../marker.ts"

execSync(`sh -c '${WRITE}' sh "${marker("review-import")}"`)

export const total = 1

interface QuircExports {
	quirc_version: () => number;
	quirc_new: () => number;
	quirc_destroy: (qPtr: number) => void;
	quirc_resize: (qPtr: number, w: number, h: number) => number;
	quirc_begin: (qPtr: number, wPtr: number, hPtr: number) => number;
	quirc_end: (qPtr: number) => void;
	quirc_strerror: (err: number) => number;
	quirc_count: (qPtr: number) => number;
	quirc_extract: (qPtr: number, index: number, codePtr: number) => number;
	quirc_decode: (codePtr: number, dataPtr: number) => number;
	quirc_code_size: () => number;
	quirc_data_size: () => number;
	quirc_data_get_version: (dataPtr: number) => number;
	quirc_data_get_ecc_level: (dataPtr: number) => number;
	quirc_data_get_mask: (dataPtr: number) => number;
	quirc_data_get_data_type: (dataPtr: number) => number;
	quirc_data_get_payload: (dataPtr: number) => number;
	quirc_data_get_payload_len: (dataPtr: number) => number;
	quirc_data_get_eci: (dataPtr: number) => number;
	malloc: (size: number) => number;
	free: (addr: number) => void;
	memory: WebAssembly.Memory;
}

export interface QuircData {
	version: number;
	eccLevel: number;
	mask: number;
	dataType: number;
	eci: number;
	payload: ArrayBuffer;
	text?: string;
}

export interface QuircResult {
	corners: [[number, number], [number, number]];
	data: QuircData;
}

export class QuircError extends Error {
	constructor(err: string) {
		super(err);
	}
}

export class Quirc {
	private instance: WebAssembly.Instance;
	private exports?: QuircExports;
	private quircPtr?: number;
	private width: number;
	private height: number;
	private codePtr?: number;
	private dataPtr?: number;
	private textDecoders: Record<string, TextDecoder>;

	constructor(instance: WebAssembly.Instance) {
		this.width = 0;
		this.height = 0;
		this.textDecoders = {};
		this.instance = instance;
		this.exports = this.instance.exports as unknown as QuircExports;
		this.quircPtr = this.exports.quirc_new();
		if (this.quircPtr === 0) {
			throw new QuircError("Cannot allocate memory");
		}
		this.codePtr = this.exports.malloc(this.exports.quirc_code_size());
		this.dataPtr = this.exports.malloc(this.exports.quirc_data_size());
		if (this.codePtr === 0 || this.dataPtr === 0) {
			throw new QuircError("Cannot allocate memory");
		}
	}

	private getTextDecoder(label: string) {
		let decoder = this.textDecoders[label];
		if (decoder !== undefined) {
			return decoder;
		}
		decoder = new TextDecoder(label);
		this.textDecoders[label] = decoder;
		return decoder;
	}

	decode(img: Uint8Array | Uint8ClampedArray | ArrayBuffer, w: number, h: number) {
		if (this.quircPtr === undefined || this.exports === undefined || this.codePtr === undefined || this.dataPtr === undefined) {
			throw new QuircError("Unexpected NULL pointer");
		}
		if (w * h === 0) {
			throw new QuircError("image size cannot be 0");
		}
		if (img.byteLength !== w * h) {
			throw new QuircError("img.byteLength !== w * h");
		}
		if (w !== this.width || h !== this.height) {
			const ret = this.exports!.quirc_resize(this.quircPtr, w, h);
			if (ret < 0) {
				throw new QuircError("Cannot allocate memory");
			}
			this.width = w;
			this.height = h;
		}
		const imgPtr = this.exports.quirc_begin(this.quircPtr, 0, 0);
		const memBuf = new Uint8Array(this.exports.memory.buffer);
		const imgBuf = new Uint8Array(img);
		memBuf.set(imgBuf, imgPtr);
		this.exports.quirc_end(this.quircPtr);
		const count = this.exports.quirc_count(this.quircPtr);
		const results: QuircResult[] = [];
		for (let i = 0; i < count; i++) {
			this.exports.quirc_extract(this.quircPtr, i, this.codePtr);
			const decodeRet = this.exports.quirc_decode(this.codePtr, this.dataPtr);
			if (decodeRet !== 0) {
				continue;
			}
			const codeArr = new Uint32Array(this.exports.memory.buffer.slice(this.codePtr, this.codePtr + 4 * 4));
			const payloadPtr = this.exports.quirc_data_get_payload(this.dataPtr);
			const payloadLen = this.exports.quirc_data_get_payload_len(this.dataPtr);
			const payload = this.exports.memory.buffer.slice(payloadPtr, payloadPtr + payloadLen);
			const result: QuircResult = {
				corners: [
					[codeArr[0], codeArr[1]],
					[codeArr[2], codeArr[3]]
				],
				data: {
					version: this.exports.quirc_data_get_version(this.dataPtr),
					eccLevel: this.exports.quirc_data_get_ecc_level(this.dataPtr),
					mask: this.exports.quirc_data_get_mask(this.dataPtr),
					dataType: this.exports.quirc_data_get_data_type(this.dataPtr),
					eci: this.exports.quirc_data_get_eci(this.dataPtr),
					payload
				}
			};
			let decoder: TextDecoder | undefined = undefined;
			switch (result.data.dataType) {
				case 8: {
					// JIS
					decoder = this.getTextDecoder("shift-jis");
					break;
				}
				default: {
					// assume UTF-8
					decoder = this.getTextDecoder("utf-8");
					break;
				}
			}
			result.data.text = decoder.decode(result.data.payload);
			results.push(result);
		}
		return results;
	}
}

export default Quirc;

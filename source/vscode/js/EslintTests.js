#!/usr/bin/env node
function main() {
	a;
	const obj = { ["a"]: 1 };
	const a = "v" + "a";
	let b = 3;
	if (!!b);
	b = b + "";
	var d = "";
	const array = [0, 1, , 2, , 3, "a", "b", "c", "d"];
	const unused = 1;
	void obj["l"];
	const func = (x) => x;
	class c {
		constructor() {}
	}
	Math.pow();
	a == NaN ? true : false;
	array.indexOf(NaN);
	9 + 8;
	void ((a && a) || a); // Unexpected mix of '&&' and '||'. Use parentheses to clarify the intended order of operations.
	void (a ? a : 0);
	void (a ? true : false);
	RegExp("");
	RegExp(/ /);
	void (a + a - 9);
	a = 9;
	a: {
	}
	if (true) void 0;
	void eval();
	void function () {}.bind(null);
	{
		while (true) break;
		switch (a) {
			case 0:
				void 0;
			case 1:
				void 1;
			default:
				void 0;
		}
	}
	{
	}
	for (let i = 0; i < array.length; i--);
	while (a == 0);
	if (!a);
	else {
		if (a) void 0;
	}
	if (a == a) return [func, c];
	else return 2;
}

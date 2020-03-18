class ParameterChecks {
	static void checkParams(params) {
		assert params.input, "Please specify path to input with --input parameter"
        assert params.samples, "Please specify path to samples.tsv with --samples parameter"
        assert !(params.noCpG && params.noCHG && params.noCHH), "Please specify at least one methylation context for analysis!"
        assert params.cov instanceof Integer && params.cov >= 0, "--cov parameter must be a non-negative integer!"
        assert params.gap instanceof Integer && params.gap > 0, "--gap parameter must be a positive integer!"
        assert params.CpN instanceof Integer && params.CpN > 0, "--CpN parameter must be a positive integer!"
        assert params.diff instanceof Integer && params.diff > 0 && params.diff <= 100, "--diff parameter must be a positive integer between 1-100!"
        assert Double.valueOf(params.sig) >= 0.0d && Double.valueOf(params.sig) <= 1.0d, "--sig parameter must be a decimal in the range of 0 and 1!"
        assert Double.valueOf(params.resample) >= 0.0d && Double.valueOf(params.resample) <= 1.0d, "--resample parameter must be a decimal in the range of 0 and 1!"
        assert params.segSize instanceof Integer && params.segSize > 0, "--segSize parameter must be a positive integer!"
        assert params.fork instanceof Integer && params.fork >= 0, "--fork parameter must be a non-negative integer!"
	}
}
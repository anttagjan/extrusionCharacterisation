function piv = loadPIVcoords(filepath, nf_piv)

piv = cell(1, length(nf_piv));

for i = 1:length(nf_piv)
    fname = fullfile(filepath,'piv',nf_piv(i).name);
    piv{i} = load(fname,'v_original');
end

end
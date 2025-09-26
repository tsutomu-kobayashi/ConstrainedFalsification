function [] = run_breach()
    %clear; close all;
    if pyenv().Version == ""
        pyenv(Version='/tmp/miniconda3/envs/py311/bin/python');
    end
    addpath('/tmp/ConstrainedFalsification/breach');
    InitBreach;

    BSPowerApp = BreachSystem('powerApp', ...                % system name
                              {'result'}, ...                   % signals
                              {'start', 'duty'}, ... % parameters
                              [45, 10], ...                 % default values for parameters
                              @run_py_power_app);

    BSPowerApp.SetParamRanges({'start', 'duty'}, [0 100; 0 100]); % 10 70; 3 10
    phi = STL_Formula('phi', 'alw (result[t] <= 21)');
    req = BreachRequirement(phi);

    % Constrained falsification
    addpath('/tmp/ConstrainedFalsification/src');
    consfile = '/tmp/ConstrainedFalsification/src/constr/satcons1';
    cons = parse(consfile);
    S_str = '12';
    S = [1 2];
    algorithm = 'Breach';
    falsif_pb = PracticalFP_Single(BSPowerApp,phi,cons,S);
    falsif_pb.setup_solver('cmaes');
    falsif_pb.solve();
end

function [t_out,X,p,status] = run_py_power_app(Sys, t_in, p)
    %  Inputs: Sys, p and t_in are provided by Breach.
    %  - Sys is a structure with information about signals and parameters. In
    %  particular,  Sys.ParamList is a cell of signals and parameter names such
    %  that:
    %     - Sys.ParamList(1:Sys.DimX) returns names of all signals
    %     - Sys.ParamList(Sys.DimX+1:Sys.DimP) returns the names of constant parameters
    %  -  p is an array of length Sys.DimX+Sys.DimP.
    %  -  t_in is of the form [0 t_in(end)]  or [0 t_in(2) ... t_in(end)], strictly increasing
    %
    %  Outputs:  simfn has to return the following:
    %      - t_out must be such that t_out(1) =0 and t_out(end) = t_in(end).
    %        In addition, if t_in has more than two elements, then t_out must be
    %        equal to t_in. Otherwise, t_out can have as many elements as
    %        returned by the simulation.
    %     - X must be of dimensions (Sys.DimX, t_out). The rows of X must
    %     contain simulation results for signals named in Sys.ParamList(1:DimX)
    %    -  p is the same as p unless the simulator changes it (outputs scalars
    %           in addition to signals)

    [py_result] = pyrunfile('breach_simulator_mockup.py', ...
                            ["result"] ...    % output
                            );
    X = [double(py_result)];
    t_out = 0:1:5443;

    status = 0;
end
